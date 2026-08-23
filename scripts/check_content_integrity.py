#!/usr/bin/env python3
"""Vérifie le contenu pédagogique directement dans les sources Swift.

Un exercice dont la bonne réponse figure aussi parmi les leurres, une phrase
à trous sans trou, deux leurres identiques : autant de bugs invisibles à la
compilation qui ne se verraient qu'à l'usage, en pleine leçon. On les attrape
ici.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
problems = []


def read(rel):
    return (ROOT / rel).read_text()


# ---------------------------------------------------------------------------
# 1. Exercices d'orthographe
# ---------------------------------------------------------------------------
drills_src = read("Limbator/Services/OrthoDrills.swift")

DRILL_RE = re.compile(
    r'\.init\(ruleId:\s*"(?P<rule>[^"]+)",\s*module:\s*\.(?P<module>\w+),\s*kind:\s*\.(?P<kind>\w+),'
    r'(?P<body>.*?)explanation:\s*"(?P<expl>(?:[^"\\]|\\.)*)"\)',
    re.S)

drills = []
for m in DRILL_RE.finditer(drills_src):
    body = m.group("body")
    sentence = re.search(r'sentence:\s*"((?:[^"\\]|\\.)*)"', body)
    answer = re.search(r'answer:\s*"((?:[^"\\]|\\.)*)"', body)
    distractors = re.search(r'distractors:\s*\[([^\]]*)\]', body)
    drills.append({
        "rule": m.group("rule"),
        "module": m.group("module"),
        "kind": m.group("kind"),
        "sentence": sentence.group(1) if sentence else None,
        "answer": answer.group(1) if answer else None,
        "distractors": re.findall(r'"((?:[^"\\]|\\.)*)"', distractors.group(1)) if distractors else [],
        "explanation": m.group("expl"),
    })

if len(drills) < 70:
    problems.append(f"trop peu d'exercices écrits à la main : {len(drills)}")

for d in drills:
    tag = f"[{d['module']}/{d['rule']}] « {d['sentence']} »"
    if not d["sentence"]:
        problems.append(f"{tag} : phrase absente")
        continue
    if not d["answer"]:
        problems.append(f"{tag} : réponse absente")
        continue
    if d["kind"] in ("choice", "fill", "accent") and "___" not in d["sentence"]:
        problems.append(f"{tag} : phrase à trou sans marqueur ___")
    if d["kind"] == "correction" and "___" in d["sentence"]:
        problems.append(f"{tag} : un exercice de correction ne doit pas avoir de trou")
    if d["answer"] in d["distractors"]:
        problems.append(f"{tag} : la bonne réponse « {d['answer']} » figure parmi les leurres")
    if len(d["distractors"]) != len(set(d["distractors"])):
        problems.append(f"{tag} : leurres en double")
    if d["kind"] == "choice" and len(d["distractors"]) < 1:
        problems.append(f"{tag} : QCM sans leurre")
    if not d["explanation"].strip():
        problems.append(f"{tag} : explication vide")
    if len(d["explanation"]) < 20:
        problems.append(f"{tag} : explication trop courte pour apprendre quoi que ce soit")

# ---------------------------------------------------------------------------
# 2. Règles
# ---------------------------------------------------------------------------
rules_src = read("Limbator/Services/OrthoRules.swift")
rule_ids = re.findall(r'id:\s*"([\w.\-]+)",\s*\n\s*module:', rules_src)
if len(rule_ids) != len(set(rule_ids)):
    dupes = {r for r in rule_ids if rule_ids.count(r) > 1}
    problems.append(f"identifiants de règle en double : {sorted(dupes)}")

# Toute règle citée par un exercice doit exister (les règles d'homophones sont
# dérivées des familles, donc générées : on les résout contre OrthoSeeds).
seeds_src = read("Limbator/Services/OrthoSeeds.swift")
homophone_ids = {"homophones." + s for s in re.findall(r'HomophoneSet\(id:\s*"([^"]+)"', seeds_src)}
known_rules = set(rule_ids) | homophone_ids
for d in drills:
    if d["rule"] not in known_rules:
        problems.append(f"exercice rattaché à une règle inconnue : {d['rule']}")

# Les identifiants renvoyés par OrthoExplainer doivent exister eux aussi.
explainer_src = read("Limbator/Services/OrthoExplainer.swift")
for rid in re.findall(r'return\s+"((?:accents|verbEndings|agreements|doubleLetters|silentLetters|roTraps)\.[\w\-]+)"',
                      explainer_src):
    if rid not in known_rules:
        problems.append(f"OrthoExplainer renvoie une règle inexistante : {rid}")

# ---------------------------------------------------------------------------
# 3. Familles d'homophones
# ---------------------------------------------------------------------------
set_ids = re.findall(r'HomophoneSet\(id:\s*"([^"]+)"', seeds_src)
if len(set_ids) != len(set(set_ids)):
    problems.append("identifiants de familles d'homophones en double")

for chunk in re.split(r'HomophoneSet\(id:\s*"', seeds_src)[1:]:
    sid = chunk.split('"')[0]
    forms = re.findall(r'\.init\(form:\s*"([^"]*)"', chunk)
    tests = re.findall(r'test:\s*"((?:[^"\\]|\\.)*)"', chunk)
    examples = re.findall(r'example:\s*"((?:[^"\\]|\\.)*)"', chunk)
    if len(forms) != len(set(forms)):
        problems.append(f"famille {sid} : graphie répétée")
    if len(tests) != len(forms):
        problems.append(f"famille {sid} : {len(forms)} graphies mais {len(tests)} tests")
    for form, example in zip(forms, examples):
        words = [w.strip(".,;:!?«»\"()").lower() for w in example.split()]
        if form.lower() not in words:
            problems.append(
                f"famille {sid} : « {form} » n'apparaît pas comme mot entier "
                f"dans son exemple « {example} »")

# ---------------------------------------------------------------------------
# 4. Dictées
# ---------------------------------------------------------------------------
dict_path = ROOT / "Limbator/Services/DictationBank.swift"
dictations = []
if dict_path.exists():
    dict_src = dict_path.read_text()
    for m in re.finditer(
            r'\.init\(text:\s*"((?:[^"\\]|\\.)*)",\s*translation:\s*"((?:[^"\\]|\\.)*)",\s*'
            r'level:\s*\.(\w+)(?P<rest>.*?)\)\s*,?\s*\n', dict_src, re.S):
        dictations.append({"text": m.group(1), "translation": m.group(2),
                           "level": m.group(3), "rest": m.group("rest")})
    if len(dictations) < 40:
        problems.append(f"trop peu de dictées : {len(dictations)}")
    seen = set()
    for d in dictations:
        if not d["text"].strip():
            problems.append("dictée au texte vide")
        if not d["translation"].strip():
            problems.append(f"dictée sans traduction : « {d['text']} »")
        if d["text"] in seen:
            problems.append(f"dictée en double : « {d['text']} »")
        seen.add(d["text"])
        if not d["text"].rstrip().endswith((".", "!", "?", "…", '"')):
            problems.append(f"dictée sans ponctuation finale : « {d['text']} »")
        for rid in re.findall(r'"([\w.\-]+)"', d["rest"]):
            if "." in rid and rid not in known_rules:
                problems.append(f"dictée « {d['text'][:40]}… » vise une règle inconnue : {rid}")

# ---------------------------------------------------------------------------
print(f"Exercices écrits à la main : {len(drills)}")
print(f"Règles                     : {len(rule_ids)} + {len(homophone_ids)} dérivées")
print(f"Familles d'homophones      : {len(set_ids)}")
print(f"Dictées                    : {len(dictations)}")
print()

if problems:
    print(f"{len(problems)} PROBLÈME(S) :")
    for p in problems:
        print("  -", p)
    sys.exit(1)
print("Contenu pédagogique cohérent.")
