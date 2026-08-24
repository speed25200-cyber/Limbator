#!/usr/bin/env python3
"""Vérifie que chaque appel `L.t(clé, arguments…)` correspond à son format.

`String(format:)` ne prévient pas : un argument manquant produit du charabia ou
fait tomber l'app, à l'exécution seulement, et souvent sur un écran rarement
visité. Le contrôle est donc statique.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# --- Table de référence : le roumain ---------------------------------------
localizer = (ROOT / "Limbator/Utilities/Localizer.swift").read_text()
marker = "private static let tableRO: [String: String] = ["
assert marker in localizer, "table roumaine introuvable dans le Localizer"
block = localizer.split(marker, 1)[1]
table = {}
for line in block.split("\n"):
    if line.strip() == "]":
        break
    entry = re.match(r'\s*"([a-z][\w.]*)":\s*"((?:[^"\\]|\\.)*)",?\s*$', line)
    if entry:
        table[entry.group(1)] = entry.group(2)

SPEC = re.compile(r'%(?:%|[0-9.\-+ ]*[@dfsu])')
problems = []
formatted_keys = set()   # clés effectivement appelées avec des arguments

# --- 1. Nombre d'arguments ---------------------------------------------------
for path in sorted(ROOT.glob("Limbator/**/*.swift")):
    text = path.read_text()
    for match in re.finditer(r'\bL\.t\(', text):
        # Appariement de parenthèses : les arguments contiennent des appels.
        i, depth, start = match.end(), 1, match.end()
        while i < len(text) and depth:
            if text[i] == "(": depth += 1
            elif text[i] == ")": depth -= 1
            i += 1
        inner = text[start:i - 1]

        key_match = re.match(r'\s*"([^"]+)"', inner)
        if not key_match:
            continue
        key = key_match.group(1)
        rest = inner[key_match.end():].strip()

        count = 0
        if rest.startswith(","):
            count, depth = 1, 0
            for ch in rest[1:]:
                if ch in "([{": depth += 1
                elif ch in ")]}": depth -= 1
                elif ch == "," and depth == 0: count += 1

        if key not in table:
            problems.append(f"{path.name} : clé inconnue « {key} »")
            continue

        if count > 0:
            formatted_keys.add(key)

        expected = len([s for s in SPEC.findall(table[key]) if s != "%%"])
        if expected != count:
            problems.append(
                f"{path.name} : L.t(\"{key}\") reçoit {count} argument(s), "
                f"le format en attend {expected} — « {table[key]} »")

# --- 2. Un « % » isolé dans une chaîne réellement formatée ------------------
# Ailleurs, « 100% offline » est du texte ordinaire : la surcharge sans
# argument ne passe pas par String(format:), donc le « % » est inoffensif —
# et l'écrire « %% » l'afficherait doublé.
for key in sorted(formatted_keys):
    for language, source in (("ro", table[key]),):
        if "%" in SPEC.sub("", source):
            problems.append(f"{key} ({language}) : « % » isolé dans une chaîne formatée "
                            f"— « {source} »")

# --- 3. Les trois tables déclarent-elles les mêmes spécificateurs ? ---------
# Une traduction qui perd un « %d » plante dès que la langue change.
for language in ("tableFR", "tableEN"):
    other_marker = f"private static let {language}: [String: String] = ["
    other_block = localizer.split(other_marker, 1)[1]
    for line in other_block.split("\n"):
        if line.strip() == "]":
            break
        entry = re.match(r'\s*"([a-z][\w.]*)":\s*"((?:[^"\\]|\\.)*)",?\s*$', line)
        if not entry:
            continue
        key, value = entry.group(1), entry.group(2)
        if key not in table:
            problems.append(f"{language} : clé absente du roumain — {key}")
            continue
        reference = [s for s in SPEC.findall(table[key]) if s != "%%"]
        translated = [s for s in SPEC.findall(value) if s != "%%"]
        if reference != translated:
            problems.append(
                f"{language}/{key} : spécificateurs différents du roumain "
                f"({reference} contre {translated})")

print(f"Clés analysées : {len(table)}")
print()
if problems:
    print(f"{len(problems)} PROBLÈME(S) :")
    for problem in sorted(set(problems)):
        print("  -", problem)
    sys.exit(1)
print("Tous les appels L.t correspondent à leur format, dans les trois langues.")
