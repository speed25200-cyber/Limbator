#!/usr/bin/env python3
"""Exécute la logique d'orthographe de Limbator et la confronte à des faits.

Le Swift ne se compile pas sur Linux. `ortho_port.py` en est la transposition
fidèle : ce fichier fait tourner cette transposition sur des cas réels du
français et échoue si une réponse est fausse. Les tables (pièges roumains,
familles d'homophones) sont LUES DANS LE SWIFT — elles ne peuvent donc pas
diverger silencieusement.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ortho_port import (sound_key, are_homophones, classify, HOMOPHONE_SETS,
                        RO_TRAPS, skeleton, collapse_doubles)

failures = []


def check(label, got, want):
    if got != want:
        failures.append(f"{label}: obtenu {got!r}, attendu {want!r}")


# ---------------------------------------------------------------------------
print("1. Phonétisation — les homophones doivent se rencontrer")
HOMOPHONE_GROUPS = [
    ["a", "à"], ["ou", "où"], ["et", "est"], ["son", "sont"], ["on", "ont"],
    ["ces", "ses", "c'est", "s'est", "sais", "sait"],
    ["la", "là", "l'a"], ["mais", "mes", "met", "mets", "mai"],
    ["peu", "peut", "peux"], ["quand", "quant", "qu'en"], ["près", "prêt"],
    ["leur", "leurs"], ["tout", "tous", "toux"],
    ["sans", "s'en", "cent", "sang"], ["temps", "tant", "t'en"],
    ["sur", "sûr"], ["du", "dû"], ["sa", "ça"],
    ["vert", "verre", "vers", "ver"], ["mer", "mère", "maire"],
    ["voix", "voie", "vois", "voit"], ["ni", "n'y"], ["si", "s'y"],
    ["fin", "faim"], ["ce", "se"],
    ["parlé", "parler", "parlez", "parlait", "parlais", "parlaient"],
    ["mange", "mangent"], ["eau", "au", "haut"], ["cour", "cours", "court"],
    ["père", "paire", "pair"], ["foi", "foie", "fois"],
]
for group in HOMOPHONE_GROUPS:
    keys = {w: sound_key(w) for w in group}
    for other in group[1:]:
        if not are_homophones(group[0], other):
            failures.append(
                f"homophones non reconnus : {group[0]} ({keys[group[0]]}) "
                f"vs {other} ({keys[other]})")

# ---------------------------------------------------------------------------
print("2. Phonétisation — les non-homophones doivent rester distincts")
DISTINCT_PAIRS = [
    ("pain", "peine"), ("dessus", "dessous"), ("poisson", "poison"),
    ("bon", "banc"), ("vin", "vent"), ("chat", "chaud"),
    ("naïf", "nef"), ("maïs", "mais"), ("le", "les"),
    ("parle", "parler"), ("dessert", "désert"), ("plus", "pluie"),
]
for a, b in DISTINCT_PAIRS:
    if are_homophones(a, b):
        failures.append(f"faussement homophones : {a} ({sound_key(a)}) / {b} ({sound_key(b)})")

# ---------------------------------------------------------------------------
print("3. Cohérence des familles d'homophones déclarées dans OrthoSeeds.swift")
for s in HOMOPHONE_SETS:
    forms = s["forms"]
    if len(forms) < 2:
        failures.append(f"famille {s['id']} : moins de deux graphies")
    base = forms[0]
    for other in forms[1:]:
        if not are_homophones(base, other):
            failures.append(
                f"famille {s['id']} : « {base} » ({sound_key(base)}) et "
                f"« {other} » ({sound_key(other)}) ne sonnent pas pareil")

# ---------------------------------------------------------------------------
print("4. Classification des fautes")
CLASSIFY_CASES = [
    # accents
    ("élève", "eleve", "accentMissing"),
    ("élève", "élêve", "accentWrong"),
    ("français", "francais", "cedillaMissing"),
    ("Noël", "Noel", "tremaMissing"),
    ("écrire", "ecrire", "accentMissing"),
    # homophones — doivent primer sur « accent oublié »
    ("à", "a", "homophone"),
    ("où", "ou", "homophone"),
    ("là", "la", "homophone"),
    ("sûr", "sur", "homophone"),
    ("c'est", "s'est", "homophone"),
    ("ces", "ses", "homophone"),
    ("sont", "son", "homophone"),
    ("ont", "on", "homophone"),
    ("peut", "peu", "homophone"),
    ("leurs", "leur", "homophone"),
    # terminaisons verbales
    ("mangé", "manger", "verbEnding"),
    ("parler", "parlé", "verbEnding"),
    ("chanté", "chantez", "verbEnding"),
    # accords
    ("cueillies", "cueilli", "agreement"),
    ("grandes", "grande", "agreement"),
    ("journaux", "journals", "agreement"),
    # consonnes doubles hors table roumaine
    ("pomme", "pome", "doubleConsonant"),
    ("belle", "bele", "doubleConsonant"),
    # calques du roumain — reconnus nommément
    ("attention", "atention", "romanianInterference"),
    ("adresse", "adrese", "romanianInterference"),
    ("fenêtre", "fenetre", "romanianInterference"),
    ("hôpital", "hopital", "romanianInterference"),
    ("professeur", "profesor", "romanianInterference"),
    ("appeler", "apeler", "romanianInterference"),
    ("théâtre", "teatre", "romanianInterference"),
    # lettres muettes
    ("petit", "peti", "silentLetter"),
    ("grand", "gran", "silentLetter"),
    # typographie
    ("l'ami", "lami", "elision"),
    ("peut-être", "peutêtre", "hyphen"),
    ("œuf", "oeuf", "ligature"),
    ("Paris", "paris", "capitalization"),
]
for expected, written, want in CLASSIFY_CASES:
    check(f"classify({expected!r}, {written!r})", classify(expected, written), want)

# ---------------------------------------------------------------------------
print("5. Intégrité des tables lues dans le Swift")
if len(RO_TRAPS) < 50:
    failures.append(f"trop peu de pièges roumains : {len(RO_TRAPS)}")
if len(HOMOPHONE_SETS) < 20:
    failures.append(f"trop peu de familles d'homophones : {len(HOMOPHONE_SETS)}")
for french, calques in RO_TRAPS.items():
    if not calques:
        failures.append(f"piège « {french} » sans graphie fautive")
    for c in calques:
        if c == french:
            failures.append(f"piège « {french} » : la graphie fautive est la bonne")

# ---------------------------------------------------------------------------
print()
if failures:
    print(f"{len(failures)} ÉCHEC(S) :")
    for f in failures:
        print("  -", f)
    sys.exit(1)

print(f"Tout passe — {len(HOMOPHONE_GROUPS)} groupes phonétiques, "
      f"{len(HOMOPHONE_SETS)} familles déclarées, {len(RO_TRAPS)} pièges roumains, "
      f"{len(CLASSIFY_CASES)} classifications.")
