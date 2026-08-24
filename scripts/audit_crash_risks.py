#!/usr/bin/env python3
"""Repère les constructions qui font planter une app iOS en production.

Une app d'apprentissage qui se ferme brutalement perd son utilisateur pour de
bon. Ces motifs sont donc traités comme des défauts, pas comme des libertés de
style : déballage forcé, `try!`, conversion forcée, `fatalError`, et surtout
l'indexation directe d'un tableau, qui reste la première cause d'arrêt brutal
en Swift.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SWIFT = sorted(list(ROOT.glob("Limbator/**/*.swift")) + list(ROOT.glob("LimbatorTests/**/*.swift")))

findings = []


def strip_comments_and_strings(text: str) -> list:
    """Rend les lignes débarrassées des commentaires et des chaînes."""
    lines = []
    in_block = False
    for line in text.splitlines():
        working = line
        if in_block:
            if "*/" in working:
                working = working.split("*/", 1)[1]
                in_block = False
            else:
                lines.append("")
                continue
        if "/*" in working:
            before, _, after = working.partition("/*")
            if "*/" in after:
                working = before + after.split("*/", 1)[1]
            else:
                working = before
                in_block = True
        working = re.sub(r'//.*$', '', working)
        working = re.sub(r'"(?:[^"\\]|\\.)*"', '""', working)
        lines.append(working)
    return lines


# L'indexation par une variable bornée par sa boucle (`chars[i + 1]` sous
# `i + 1 < n`) est correcte et omniprésente dans les algorithmes d'alignement :
# la signaler noierait les vrais défauts. Ce qui est traqué ici, c'est
# l'indexation LITTÉRALE d'une collection partagée — `Story.builtIn[0]`,
# `curriculum[0]`, `urls(...)[0]` — parce qu'elle suppose un contenu que rien
# ne garantit, et que c'est ainsi qu'une app se ferme au lancement.
RULES = [
    ("try!", re.compile(r'\btry!\s')),
    ("conversion forcée", re.compile(r'\bas!\s')),
    ("fatalError", re.compile(r'\bfatalError\s*\(')),
    ("preconditionFailure", re.compile(r'\bpreconditionFailure\s*\(')),
    ("indexation littérale d\'une collection partagée",
     re.compile(r'(?:\w+\.\w+|\))\s*\[\s*\d+\s*\]')),
]

# `!` légitimes : négation booléenne, opérateurs, et l'accès aux membres
# implicitement déballés d'Apple qui ne peuvent pas être nil ici.
FORCE_UNWRAP_ALLOWED = re.compile(r'(?:^|\W)!(?:\w|\()')

for path in SWIFT:
    relative = str(path.relative_to(ROOT))
    for number, line in enumerate(strip_comments_and_strings(path.read_text()), 1):
        stripped = line.strip()
        if not stripped:
            continue

        # Déballage forcé : un identifiant suivi de `!`, hors `!=` et hors
        # négation booléenne.
        for match in re.finditer(r'\b([A-Za-z_]\w*)!', line):
            if line[match.end():match.end() + 1] == "=":
                continue
            before = line[:match.start()].rstrip()
            if before.endswith(("!", "=", "<", ">", "&", "|")):
                continue
            findings.append((relative, number, "déballage forcé", stripped[:100]))

        for label, pattern in RULES:
            if pattern.search(line):
                findings.append((relative, number, label, stripped[:100]))

# ---------------------------------------------------------------------------
# Exemptions justifiées, une par une.
# ---------------------------------------------------------------------------
EXEMPT = set()

real = [f for f in findings if (f[0], f[2]) not in EXEMPT]

by_kind = {}
for _, _, label, _ in real:
    by_kind[label] = by_kind.get(label, 0) + 1

print(f"Fichiers analysés : {len(SWIFT)}")
if by_kind:
    for label, count in sorted(by_kind.items()):
        print(f"  {label} : {count}")
print()

if real:
    print(f"{len(real)} RISQUE(S) D'ARRÊT BRUTAL :")
    for relative, number, label, snippet in real[:40]:
        print(f"  {relative}:{number}  [{label}]  {snippet}")
    if len(real) > 40:
        print(f"  … et {len(real) - 40} autres")
    sys.exit(1)

print("Aucune construction pouvant provoquer un arrêt brutal.")
