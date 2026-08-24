#!/usr/bin/env python3
"""Cherche les fautes SwiftUI qui ne se voient qu'à la compilation.

Aucun compilateur Swift n'est disponible ici ; or deux fautes très banales ne
se voient qu'à la compilation, et le message d'erreur produit par Xcode
(« unable to type-check this expression in reasonable time ») ne désigne même
pas la ligne fautive. On les cherche donc dans l'arbre syntaxique.

RÈGLE 1 — arité de `buildBlock`.
    Un conteneur SwiftUI accepte **au plus dix vues filles**. La onzième ne
    produit pas un avertissement : elle produit un échec de compilation dont
    le message parle d'inférence de types. On compte donc les instructions de
    premier niveau dans chaque fermeture de conteneur.

RÈGLE 2 — `@ViewBuilder` manquant.
    Une fonction qui renvoie `some View` renvoie **un seul type concret**. Si
    son corps se ramifie et que les branches produisent des types différents —
    le cas ordinaire dans une vue — le code ne compile pas, sauf si
    `@ViewBuilder` les enveloppe dans un `_ConditionalContent`. Depuis Swift
    5.9 un `if` dont toutes les branches ont le même type est une expression
    valide, et l'attribut n'est alors pas indispensable ; le signalement reste
    juste, parce que l'ajouter n'est jamais faux et qu'une branche ajoutée plus
    tard casserait la compilation sans prévenir.

    `var body` est le seul cas où l'attribut est implicite : le protocole
    `View` le déclare lui-même.
"""
import sys
from pathlib import Path
import tree_sitter
import tree_sitter_swift

LANG = tree_sitter.Language(tree_sitter_swift.language())
PARSER = tree_sitter.Parser(LANG)

# Conteneurs dont la fermeture finale est, sans ambiguïté, un `@ViewBuilder`.
# `Button` en est volontairement absent : `Button("x") { … }` prend une action,
# pas des vues, et le confondre produirait de faux positifs.
CONTAINERS = {
    "VStack", "HStack", "ZStack", "Group", "ScrollView", "List", "Form",
    "Section", "NavigationStack", "NavigationView", "NavigationSplitView",
    "LazyVStack", "LazyHStack", "LazyVGrid", "LazyHGrid", "TabView",
    "ForEach", "ViewThatFits", "GeometryReader", "ScrollViewReader",
}
MAX_CHILDREN = 10

# Instructions qui ne produisent pas de vue : elles ne comptent pas dans
# l'arité de `buildBlock`.
NON_VIEW_STMT = {
    "property_declaration", "function_declaration", "class_declaration",
    "typealias_declaration", "import_declaration", "assignment",
    "comment", "multiline_comment",
}


def text(node, src):
    return src[node.start_byte:node.end_byte].decode("utf-8", "replace")


def statements_of(block):
    """Les instructions de premier niveau d'un `{ … }`, ou None."""
    for child in block.children:
        if child.type == "statements":
            return [c for c in child.children if c.is_named]
    return None


def trailing_lambda(call):
    """La fermeture finale d'un `call_expression`, si elle existe."""
    for child in call.children:
        if child.type == "call_suffix":
            for sub in child.children:
                if sub.type == "lambda_literal":
                    return sub
    return None


def callee_name(call, src):
    first = call.children[0] if call.children else None
    if first is None:
        return ""
    if first.type == "simple_identifier":
        return text(first, src)
    # `SwiftUI.VStack { … }` ou `Foo.bar { … }`
    if first.type == "navigation_expression":
        parts = text(first, src).split(".")
        return parts[-1] if parts else ""
    return ""


def has_view_builder(decl, src):
    for child in decl.children:
        if child.type == "modifiers":
            if "@ViewBuilder" in text(child, src):
                return True
    return False


def returns_some_view(decl, src):
    for child in decl.children:
        if child.type == "opaque_type" and "View" in text(child, src):
            return True
        if child.type == "type_annotation":
            for sub in child.children:
                if sub.type == "opaque_type" and "View" in text(sub, src):
                    return True
    return False


def body_block(decl):
    for child in decl.children:
        if child.type in ("computed_property", "function_body"):
            return child
    return None


def decl_name(decl, src):
    for child in decl.children:
        if child.type == "pattern":
            return text(child, src).strip()
        if child.type == "simple_identifier":
            return text(child, src).strip()
    return "<?>"


def check(path):
    src = path.read_bytes()
    tree = PARSER.parse(src)
    problems = []

    def visit(node):
        # RÈGLE 1 — conteneurs trop peuplés.
        if node.type == "call_expression":
            name = callee_name(node, src)
            if name in CONTAINERS:
                lam = trailing_lambda(node)
                if lam is not None:
                    stmts = statements_of(lam) or []
                    views = [s for s in stmts if s.type not in NON_VIEW_STMT]
                    if len(views) > MAX_CHILDREN:
                        problems.append(
                            (node.start_point[0] + 1,
                             f"{name} contient {len(views)} vues filles "
                             f"(maximum {MAX_CHILDREN}) — extraire un sous-groupe"))

        # RÈGLE 2 — `some View` ramifié sans `@ViewBuilder`.
        if node.type in ("property_declaration", "function_declaration"):
            if returns_some_view(node, src) and not has_view_builder(node, src):
                name = decl_name(node, src)
                if name != "body":
                    block = body_block(node)
                    stmts = statements_of(block) if block is not None else None
                    if stmts:
                        for s in stmts:
                            if s.type in ("if_statement", "switch_statement"):
                                # Un `if` qui `return` explicitement est licite :
                                # c'est une sortie anticipée, pas une branche de vue.
                                if "return" not in text(s, src):
                                    problems.append(
                                        (s.start_point[0] + 1,
                                         f"`{name}` renvoie `some View` et commence par un "
                                         f"`{s.type.split('_')[0]}` sans @ViewBuilder"))
                                break
                        # Plusieurs vues sans @ViewBuilder ni `return` : même faute.
                        views = [s for s in stmts if s.type not in NON_VIEW_STMT]
                        if len(views) > 1 and not any(
                                "return" in text(s, src) for s in stmts):
                            problems.append(
                                (node.start_point[0] + 1,
                                 f"`{name}` renvoie `some View` mais son corps a "
                                 f"{len(views)} expressions sans @ViewBuilder"))

        for child in node.children:
            visit(child)

    visit(tree.root_node)
    return problems


def main():
    root = Path(__file__).resolve().parent.parent
    files = sorted(root.glob("Limbator/**/*.swift")) + sorted(root.glob("LimbatorTests/**/*.swift"))

    total = 0
    for f in files:
        for line, msg in sorted(check(f)):
            print(f"✗ {f.relative_to(root)}:{line}: {msg}")
            total += 1
    print(f"\nAnalysé {len(files)} fichiers SwiftUI — {total} problème(s)")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
