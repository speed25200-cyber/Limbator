#!/usr/bin/env python3
"""Vérifie que chaque `switch` sur une énumération du projet est exhaustif.

Swift refuse de compiler un switch incomplet sans `default`. C'est précisément
l'erreur qu'on introduit en ajoutant un cas — un module d'orthographe, un jeu,
une catégorie de faute — et qu'on ne découvrirait qu'au premier build macOS,
plusieurs minutes plus tard.
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from swiftlex import strip_noise, enum_cases

ROOT = Path(__file__).resolve().parent.parent
SWIFT = sorted(list(ROOT.glob("Limbator/**/*.swift")) + list(ROOT.glob("LimbatorTests/**/*.swift")))
CODE = {path: strip_noise(path.read_text()) for path in SWIFT}
ALL = "\n".join(CODE.values())

# Les énumérations dont un switch incomplet casserait la compilation.
ENUMS = ["OrthoModule", "OrthoErrorKind", "GameKind", "ProficiencyLevel",
         "LimbIllustration"]
CASES = {name: enum_cases(ALL, name) for name in ENUMS}

problems = []
checked = 0

for name, cases in CASES.items():
    if not cases:
        problems.append(f"aucun cas lisible pour {name}")

SWITCH = re.compile(r'^([ \t]*)switch\s+(.+?)\s*\{', re.M)

for path, text in CODE.items():
    lines = text.split("\n")
    for match in SWITCH.finditer(text):
        subject = match.group(2)
        start = text[:match.start()].count("\n")

        # Corps du switch, accolades appariées.
        body, depth = [], 0
        for i in range(start, len(lines)):
            depth += lines[i].count("{") - lines[i].count("}")
            body.append(lines[i])
            if i > start and depth <= 0:
                break
        body_text = "\n".join(body)

        if re.search(r'^\s*default\s*:', body_text, re.M):
            continue

        # Les cas traités, listes multilignes comprises.
        handled, buffer = set(), ""
        for line in body_text.split("\n"):
            stripped = line.strip()
            if buffer:
                buffer += " " + stripped
            elif stripped.startswith("case "):
                buffer = stripped[5:]
            else:
                continue
            if buffer.rstrip().endswith(","):
                continue
            for token in re.findall(r'\.([a-z]\w*)', buffer.split(":")[0]):
                handled.add(token)
            buffer = ""

        # Quelle énumération ? Celle dont ce switch couvre le plus de cas.
        best, score = None, 0
        for name, cases in CASES.items():
            covered = len(handled & set(cases))
            if covered > score:
                best, score = name, covered
        # Deux cas suffisent à identifier, mais on exige que le switch couvre
        # une part sérieuse de l'énumération : sinon c'est un switch sur autre
        # chose qui partage quelques noms.
        if best is None or score < 2 or score < len(CASES[best]) * 0.5:
            continue

        checked += 1
        missing = [case for case in CASES[best] if case not in handled]
        if missing:
            problems.append(
                f"{path.relative_to(ROOT)}:{start + 1} — switch sur {best} "
                f"« {subject[:36]} » sans `default` : {', '.join(missing)}")

for name, cases in CASES.items():
    print(f"{name:18} : {len(cases)} cas")
print(f"\nswitch analysés : {checked}")
print()

if problems:
    unique = sorted(set(problems))
    print(f"{len(unique)} SWITCH INCOMPLET(S) :")
    for problem in unique:
        print("  -", problem)
    sys.exit(1)
print("Tous les switch sur énumération sont exhaustifs.")
