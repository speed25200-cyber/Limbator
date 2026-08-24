#!/usr/bin/env python3
"""Vérifie que ce que le code appelle existe réellement.

Le compilateur Swift ferait ce travail, mais il n'est pas disponible sur Linux.
Trois contrôles couvrent l'essentiel des ruptures possibles :

  1. Toute clé passée à `L.t(...)` est déclarée dans le Localizer.
  2. Tout cas d'énumération utilisé existe bien.
  3. Tout type du projet référencé est déclaré quelque part.

Les commentaires et les chaînes sont retirés avant analyse : le contenu
pédagogique est écrit en français et en roumain, et sans ce nettoyage chaque
nom propre d'une phrase d'exemple passerait pour un type manquant.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SWIFT = sorted(list(ROOT.glob("Limbator/**/*.swift")) + list(ROOT.glob("LimbatorTests/**/*.swift")))

problems = []


def strip_noise(text: str) -> str:
    """Retire commentaires et littéraux de chaîne, en gardant les retours à la ligne."""
    out = []
    i, n = 0, len(text)
    while i < n:
        ch = text[i]
        if ch == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if ch == "/" and i + 1 < n and text[i + 1] == "*":
            depth, i = 1, i + 2
            while i < n and depth:
                if text.startswith("/*", i):
                    depth += 1; i += 2
                elif text.startswith("*/", i):
                    depth -= 1; i += 2
                else:
                    if text[i] == "\n":
                        out.append("\n")
                    i += 1
            continue
        if text.startswith('"""', i):
            i += 3
            while i < n and not text.startswith('"""', i):
                if text[i] == "\n":
                    out.append("\n")
                i += 1
            i += 3
            continue
        if ch == '"':
            i += 1
            while i < n and text[i] != '"':
                # L'interpolation contient du vrai code : on la conserve.
                if text.startswith("\\(", i):
                    depth, i = 1, i + 2
                    while i < n and depth:
                        if text[i] == "(":
                            depth += 1
                        elif text[i] == ")":
                            depth -= 1
                        if depth:
                            out.append(text[i])
                        i += 1
                    continue
                if text[i] == "\\":
                    i += 2
                    continue
                i += 1
            i += 1
            out.append(' ""$ ')
            continue
        out.append(ch)
        i += 1
    return "".join(out)


RAW = {path: path.read_text() for path in SWIFT}
CODE = {path: strip_noise(text) for path, text in RAW.items()}
ALL_CODE = "\n".join(CODE.values())


def rel(path):
    return str(path.relative_to(ROOT))


# ---------------------------------------------------------------------------
# 1. Clés de localisation
# ---------------------------------------------------------------------------
localizer = RAW[ROOT / "Limbator/Utilities/Localizer.swift"]
declared_keys = set(re.findall(r'^\s+"([a-z][\w.]*)":\s*"', localizer, re.M))

used_keys = set()
for path, text in RAW.items():
    # Les tests emploient volontairement une clé absente pour vérifier le
    # repli : les inclure ici ferait échouer le contrôle sur une intention.
    if "LimbatorTests" in str(path):
        continue
    for key in re.findall(r'L\.t\(\s*"([^"]+)"', text):
        used_keys.add((key, rel(path)))

for key, where in sorted(used_keys):
    if key not in declared_keys:
        problems.append(f"{where} : clé absente du Localizer — {key}")

# Le contrôle vaut dans les deux sens. Une clé traduite en trois langues que
# personne n'affiche n'est pas seulement du poids mort : relue plus tard, elle
# laisse croire que l'écran correspondant existe. Vingt-cinq d'entre elles
# décrivaient des vues jamais construites.
unused_keys = declared_keys - {key for key, _ in used_keys}
for key in sorted(unused_keys):
    problems.append(f"Localizer : clé traduite mais jamais affichée — {key}")

# ---------------------------------------------------------------------------
# 2. Cas d'énumération
# ---------------------------------------------------------------------------
def enum_body(name: str) -> str:
    match = re.search(rf'\benum\s+{name}\b[^{{]*\{{', ALL_CODE)
    if not match:
        return ""
    start = match.end()
    depth, i = 1, start
    while i < len(ALL_CODE) and depth:
        if ALL_CODE[i] == "{":
            depth += 1
        elif ALL_CODE[i] == "}":
            depth -= 1
        i += 1
    return ALL_CODE[start:i]


def enum_cases(name: str) -> set:
    body = enum_body(name)
    names = set()
    for line in re.findall(r'^\s*case\s+(.+)$', body, re.M):
        for part in line.split(","):
            token = part.strip().split("(")[0].split("=")[0].split(":")[0].strip()
            if re.fullmatch(r'[a-z]\w*', token):
                names.add(token)
    return names


def enum_members(name: str) -> set:
    """Les membres non-cas : propriétés et méthodes statiques ou d'instance."""
    body = enum_body(name)
    members = set(re.findall(r'\b(?:static\s+)?(?:let|var|func)\s+(\w+)', body))
    return members


for enum_name in ("LimbIcon", "OrthoModule", "GameKind", "OrthoErrorKind",
                  "ProficiencyLevel", "OrthoDrill", "LimbIllustration"):
    cases = enum_cases(enum_name)
    if not cases and enum_name not in ("OrthoDrill",):
        problems.append(f"aucun cas lisible pour {enum_name}")
        continue
    allowed = cases | enum_members(enum_name) | {
        "self", "allCases", "RawValue", "init", "Kind", "Rarity", "State",
        "Gender", "Voice", "Delivery", "Engine", "Variant", "seedHash",
    }
    for path, text in CODE.items():
        for used in re.findall(rf'\b{enum_name}\.(\w+)', text):
            if used not in allowed:
                problems.append(f"{rel(path)} : {enum_name}.{used} n'existe pas")

# ---------------------------------------------------------------------------
# 3. Types du projet
# ---------------------------------------------------------------------------
DECL = re.compile(r'\b(?:struct|class|enum|protocol|actor|typealias)\s+([A-Z]\w*)')
declared_types = set()
for text in CODE.values():
    declared_types |= set(DECL.findall(text))

# Les types du projet suivent des préfixes reconnaissables ; on ne vérifie
# qu'eux, le reste appartenant à Apple ou aux paquets tiers.
PROJECT_PREFIXES = ("Limb", "Ortho", "French", "Romanian", "Dictation", "Story",
                    "Lesson", "Vocab", "Game", "Mastery", "Homophone", "Badge",
                    "Native", "Proficiency", "Content", "Gemma", "TTS", "Azure",
                    "Neural", "Spaced", "Progress", "App", "Theme", "Flag",
                    "Speaker", "Listen", "Mastery", "Section", "Primary",
                    "Ghost", "Glowing", "Confetti", "Aurora", "Star", "Accent",
                    "Score", "Mistake", "Flow", "Wheel", "Quiz", "Flash", "Word",
                    "Speaking", "Tutor", "Profile", "Home", "Main", "Root",
                    "Module", "Rule", "Example", "Voice", "WAV", "Chunk", "Chip",
                    "Diamond", "Triangle", "Topic", "Highlighted", "Proficiency")

# Types Apple qui tombent malencontreusement sous un préfixe du projet.
APPLE_COLLISIONS = {"MainActor", "ProgressView", "AppStorage", "AppDelegate",
                    "ThemeKey", "StoryboardSegue", "GameController"}

for path, text in CODE.items():
    for name in set(re.findall(r'\b([A-Z]\w{2,})(?=[\.\(<\s]*[\.\(<])', text)):
        if name in declared_types or name in APPLE_COLLISIONS:
            continue
        if not name.startswith(PROJECT_PREFIXES):
            continue
        problems.append(f"{rel(path)} : type du projet référencé mais non déclaré — {name}")

# ---------------------------------------------------------------------------
# 4. Vues jamais posées à l'écran
# ---------------------------------------------------------------------------
# Une `View` que personne n'instancie est du code mort qui se lit comme une
# fonctionnalité : on croit l'écran existant parce que la structure est là.
# C'était le cas d'une pluie d'étoiles décorative, écrite et jamais affichée.

view_declarations = {}
for path, text in CODE.items():
    for match in re.finditer(r"\bstruct\s+([A-Z]\w+)\s*:\s*[^{]*\bView\b", text):
        view_declarations[match.group(1)] = path

for name, home in sorted(view_declarations.items()):
    uses = 0
    for path, text in CODE.items():
        hits = len(re.findall(rf"\b{name}\b", text))
        if path == home:
            hits -= len(re.findall(rf"\bstruct\s+{name}\b", text))
        uses += hits
    if uses == 0:
        problems.append(f"{rel(home)} : vue déclarée mais jamais affichée — {name}")

# ---------------------------------------------------------------------------
print(f"Fichiers Swift     : {len(RAW)}")
print(f"Vues déclarées     : {len(view_declarations)}")
print(f"Types déclarés     : {len(declared_types)}")
print(f"Clés de traduction : {len(declared_keys)} déclarées, "
      f"{len({k for k, _ in used_keys})} utilisées")
print()

if problems:
    unique = sorted(set(problems))
    print(f"{len(unique)} PROBLÈME(S) :")
    for problem in unique:
        print("  -", problem)
    sys.exit(1)
print("Toutes les références se résolvent.")
