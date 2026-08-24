#!/usr/bin/env bash
# Toute la vérification possible sans la chaîne d'outils Apple.
#
# Le compilateur Swift n'existe pas sur Linux, et les minutes macOS coûtent
# cher : ces contrôles attrapent en quelques secondes l'essentiel de ce qui
# ferait échouer une construction — ou pire, de ce qui passerait la compilation
# pour se manifester en pleine leçon.

set -e
cd "$(dirname "$0")/.."

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }
info() { echo -e "${YELLOW}→${NC} $1"; }

echo "════════════════════════════════════════════════════════════"
echo "  Limbator — vérification statique complète"
echo "════════════════════════════════════════════════════════════"
echo ""

info "1. Syntaxe Swift (tree-sitter, tous les fichiers)"
python3 scripts/check_swift_syntax.py > /tmp/limb1.log 2>&1 \
    && pass "$(grep 'Parsed' /tmp/limb1.log | xargs) — tout analyse proprement" \
    || { cat /tmp/limb1.log; fail "syntaxe Swift"; }

info "2. Références : types, cas d'énumération, clés de traduction"
python3 scripts/check_symbols.py > /tmp/limb2.log 2>&1 \
    && pass "$(grep 'Clés de traduction' /tmp/limb2.log | xargs)" \
    || { cat /tmp/limb2.log; fail "références non résolues"; }

info "3. Switch exhaustifs sur les énumérations"
python3 scripts/check_exhaustiveness.py > /tmp/limb3b.log 2>&1 \
    && pass "$(grep 'switch analysés' /tmp/limb3b.log | xargs) — tous exhaustifs" \
    || { cat /tmp/limb3b.log; fail "switch incomplet"; }

info "4. Chaînes de format et arguments, dans les trois langues"
python3 scripts/check_format_strings.py > /tmp/limb3c.log 2>&1 \
    && pass "$(tail -1 /tmp/limb3c.log | xargs)" \
    || { cat /tmp/limb3c.log; fail "chaînes de format"; }

info "5. Logique d'orthographe exécutée sur du vrai français"
python3 scripts/exec_ortho_logic.py > /tmp/limb3.log 2>&1 \
    && pass "$(tail -1 /tmp/limb3.log | xargs)" \
    || { cat /tmp/limb3.log; fail "logique d'orthographe"; }

info "6. Cohérence du contenu pédagogique"
python3 scripts/check_content_integrity.py > /tmp/limb4.log 2>&1 \
    && pass "$(grep -E 'Exercices|Dictées' /tmp/limb4.log | xargs)" \
    || { cat /tmp/limb4.log; fail "contenu pédagogique"; }

info "7. Risques d'arrêt brutal"
python3 scripts/audit_crash_risks.py > /tmp/limb5.log 2>&1 \
    && pass "$(tail -1 /tmp/limb5.log | xargs)" \
    || { cat /tmp/limb5.log; fail "risques d'arrêt brutal"; }

info "8. Fichiers structurés (JSON, plist, XML)"
python3 - > /tmp/limb6.log 2>&1 <<'PY'
import json, plistlib, sys
import xml.etree.ElementTree as ET
from pathlib import Path

errors, total = 0, 0
for path in Path(".").rglob("*.json"):
    if ".git" in str(path): continue
    try: json.loads(path.read_text()); total += 1
    except Exception as exc: print(f"{path}: {exc}"); errors += 1
for path in list(Path(".").rglob("*.plist")) + list(Path(".").rglob("*.xcprivacy")) \
        + list(Path(".").rglob("*.entitlements")):
    if ".git" in str(path): continue
    try:
        with open(path, "rb") as handle: plistlib.load(handle); total += 1
    except Exception as exc: print(f"{path}: {exc}"); errors += 1
for path in Path(".").rglob("*.xcscheme"):
    if ".git" in str(path): continue
    try: ET.parse(path); total += 1
    except Exception as exc: print(f"{path}: {exc}"); errors += 1
if errors: sys.exit(1)
print(f"{total} fichiers structurés valides")
PY
[ $? -eq 0 ] && pass "$(cat /tmp/limb6.log)" || { cat /tmp/limb6.log; fail "fichiers structurés"; }

info "9. Configuration de construction (project.yml, codemagic.yaml)"
python3 - > /tmp/limb7.log 2>&1 <<'PY'
import sys, yaml
from pathlib import Path

problems = []
project = yaml.safe_load(Path("project.yml").read_text())
assert project["name"] == "Limbator"
targets = project["targets"]
if "Limbator" not in targets: problems.append("cible application absente")
if "LimbatorTests" not in targets: problems.append("cible de tests absente")

app = targets["Limbator"]
settings = app["settings"]["base"]
if settings["PRODUCT_BUNDLE_IDENTIFIER"] != "com.limbator.app":
    problems.append("identifiant de paquet inattendu")
if "LIMB_MLX_REAL" not in settings.get("SWIFT_ACTIVE_COMPILATION_CONDITIONS[sdk=iphoneos*]", ""):
    problems.append("LIMB_MLX_REAL absent : MLX tournerait sur simulateur et ferait planter l'app")
if project["options"]["deploymentTarget"]["iOS"] != "17.0":
    problems.append("cible de déploiement inattendue")

# Un seul consommateur de mlx-swift : sinon Xcode matérialise deux fois le
# target C `Cmlx` et le graphe de dépendances échoue à se calculer.
packages = project["packages"]
if any("mlx-swift" == name for name in packages):
    problems.append("mlx-swift déclaré en direct : diamant de dépendances garanti")

codemagic = yaml.safe_load(Path("codemagic.yaml").read_text())
for flow in ("validate", "testflight", "release"):
    if flow not in codemagic["workflows"]:
        problems.append(f"flux {flow} absent de codemagic.yaml")
for name, flow in codemagic["workflows"].items():
    script_text = " ".join(step.get("script", "") for step in flow.get("scripts", []))
    if "xcodegen generate" not in script_text:
        problems.append(f"{name} : le projet Xcode n'est pas généré")
    if "IDESkipMacroFingerprintValidation" not in script_text:
        problems.append(f"{name} : macros SwiftPM non approuvées — la construction échouera")
    if "download_voice.sh" not in script_text:
        problems.append(f"{name} : les voix françaises ne sont pas récupérées")

if problems:
    for problem in problems: print(" -", problem)
    sys.exit(1)
print("project.yml et codemagic.yaml cohérents")
PY
[ $? -eq 0 ] && pass "$(cat /tmp/limb7.log)" || { cat /tmp/limb7.log; fail "configuration de construction"; }

info "10. Aucun emoji dans les sources"
python3 - > /tmp/limb8.log 2>&1 <<'PY'
import re, sys
from pathlib import Path
emoji = re.compile('[\U0001F300-\U0001FAFF\U0001F600-\U0001F64F'
                   '\U00002600-\U000027BF\U0001F1E0-\U0001F1FF]')
hits = 0
for path in list(Path("Limbator").rglob("*.swift")) + list(Path("LimbatorTests").rglob("*.swift")):
    for number, line in enumerate(path.read_text().splitlines(), 1):
        if emoji.search(line):
            print(f"{path}:{number}: {line.strip()[:80]}")
            hits += 1
sys.exit(1 if hits else 0)
PY
[ $? -eq 0 ] && pass "Aucun emoji" || { cat /tmp/limb8.log; fail "emoji trouvé"; }

info "11. Ressources indispensables"
test -f Limbator/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png \
    && pass "Icône présente ($(du -h Limbator/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png | cut -f1))" \
    || fail "icône absente"
test -f Limbator/Resources/PrivacyInfo.xcprivacy \
    && pass "Manifeste de confidentialité présent" || fail "manifeste absent"
test -f Limbator.xcodeproj/xcshareddata/xcschemes/Limbator.xcscheme \
    && pass "Schéma partagé présent" || fail "schéma absent"
test -x scripts/download_voice.sh \
    && pass "Script des voix exécutable" || fail "download_voice.sh non exécutable"

info "12. L'icône représente bien un accent AIGU"
python3 - > /tmp/limb10.log 2>&1 <<'PY'
import sys
from PIL import Image

# L'aigu monte vers la droite (é), le grave descend (è). Une icône qui se
# tromperait afficherait une faute d'orthographe sur l'écran d'accueil.
image = Image.open("Limbator/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png").convert("RGB")
w, h = image.size
pixels = image.load()

gold_left, gold_right, count = [], [], 0
for y in range(int(h * 0.18), int(h * 0.36)):
    for x in range(int(w * 0.35), int(w * 0.70)):
        r, g, b = pixels[x, y]
        if r > 180 and g > 140 and b < 150 and r > b + 60:
            count += 1
            (gold_left if x < w * 0.51 else gold_right).append(y)

if count < 500:
    print(f"accent doré introuvable ({count} pixels)"); sys.exit(1)
if not gold_left or not gold_right:
    print("accent trop étroit pour juger de son sens"); sys.exit(1)

mean_left = sum(gold_left) / len(gold_left)
mean_right = sum(gold_right) / len(gold_right)
# L'axe vertical descend : monter vers la droite veut dire y plus petit à droite.
if mean_right >= mean_left:
    print(f"l'accent DESCEND vers la droite : c'est un accent grave, pas un aigu "
          f"(gauche y={mean_left:.0f}, droite y={mean_right:.0f})")
    sys.exit(1)
print(f"accent aigu confirmé — {count} pixels dorés, "
      f"gauche y={mean_left:.0f} > droite y={mean_right:.0f}")
PY
[ $? -eq 0 ] && pass "$(cat /tmp/limb10.log)" || { cat /tmp/limb10.log; fail "orientation de l'accent"; }

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "  ${GREEN}TOUS LES CONTRÔLES STATIQUES PASSENT${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Pour finir sur un Mac :"
echo "  1. ./scripts/download_voice.sh      # voix neurales françaises"
echo "  2. xcodegen generate"
echo "  3. open Limbator.xcodeproj          # Cmd-U pour les tests, Cmd-R pour lancer"
