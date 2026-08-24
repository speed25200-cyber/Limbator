#!/usr/bin/env bash
# Récupère les deux voix neurales françaises embarquées dans l'app.
#
# MODÈLES : Piper VITS fr_FR, distribués prêts à l'emploi par le projet
# sherpa-onnx. Chaque archive contient les poids, la table de jetons ET le
# dossier espeak-ng-data — indispensable, puisque Piper phonémise le texte avant
# de le synthétiser : sans lui le moteur se charge mais ne prononce rien
# d'intelligible.
#
#   Voice/fr_female.onnx  + fr_female_tokens.txt   (siwis, voix féminine)
#   Voice/fr_male.onnx    + fr_male_tokens.txt     (tom, voix masculine)
#   Voice/espeak-ng-data/                          (phonémiseur, partagé)
#
# LICENCES : siwis est distribuée sous CC BY 4.0, tom sous CC BY 4.0 également ;
# espeak-ng est sous GPLv3. Voir VOIX.md pour le détail et les obligations
# d'attribution.
#
# Si un fichier manque au lancement, NeuralVoiceEngine.load rend nil et l'app
# retombe sur les voix Premium d'Apple — qui, pour le français, sont très bonnes.
# L'app reste donc parfaitement utilisable ; c'est un repli, pas une panne.

set -euo pipefail
cd "$(dirname "$0")/.."

VOICE_DIR="Limbator/Resources/Voice"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

BASE="https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models"
FEMALE_ARCHIVE="vits-piper-fr_FR-siwis-medium.tar.bz2"
MALE_ARCHIVE="vits-piper-fr_FR-tom-medium.tar.bz2"

mkdir -p "$VOICE_DIR"

fetch() {
    local archive="$1"
    echo "→ Téléchargement de $archive…"
    # -f fait échouer curl sur une erreur HTTP : sans lui, une réponse 404
    # s'écrirait tranquillement dans le fichier et l'archive serait « valide »
    # jusqu'à la décompression.
    curl -fL --retry 3 --retry-delay 2 -o "$WORK/$archive" "$BASE/$archive"
    tar xjf "$WORK/$archive" -C "$WORK"
}

install_voice() {
    local dir="$1" prefix="$2"
    local model tokens
    model="$(find "$WORK/$dir" -maxdepth 1 -name '*.onnx' | head -1)"
    tokens="$WORK/$dir/tokens.txt"
    [ -n "$model" ] || { echo "❌ modèle .onnx introuvable dans $dir"; exit 1; }
    [ -f "$tokens" ] || { echo "❌ tokens.txt introuvable dans $dir"; exit 1; }
    cp -f "$model" "$VOICE_DIR/${prefix}.onnx"
    cp -f "$tokens" "$VOICE_DIR/${prefix}_tokens.txt"
}

fetch "$FEMALE_ARCHIVE"
install_voice "vits-piper-fr_FR-siwis-medium" "fr_female"

fetch "$MALE_ARCHIVE"
install_voice "vits-piper-fr_FR-tom-medium" "fr_male"

# espeak-ng-data est identique dans les deux archives : une seule copie suffit.
ESPEAK_SRC="$(find "$WORK" -maxdepth 2 -type d -name 'espeak-ng-data' | head -1)"
[ -n "$ESPEAK_SRC" ] || { echo "❌ espeak-ng-data absent des archives"; exit 1; }
rm -rf "$VOICE_DIR/espeak-ng-data"
cp -R "$ESPEAK_SRC" "$VOICE_DIR/espeak-ng-data"

# ---------------------------------------------------------------------------
# Contrôles d'intégrité. Un asset tronqué ne fait pas échouer le chargement :
# il produit du bruit. Mieux vaut arrêter la construction ici, bruyamment.
# ---------------------------------------------------------------------------
check_size() {
    local file="$1" minimum="$2"
    local bytes
    bytes=$(wc -c < "$file" | tr -d ' ')
    if [ "$bytes" -lt "$minimum" ]; then
        echo "❌ $file trop petit ($bytes octets, minimum $minimum) — téléchargement incomplet"
        exit 1
    fi
    echo "  ✓ $(basename "$file") : $bytes octets"
}

check_size "$VOICE_DIR/fr_female.onnx" 10000000
check_size "$VOICE_DIR/fr_female_tokens.txt" 100
check_size "$VOICE_DIR/fr_male.onnx" 10000000
check_size "$VOICE_DIR/fr_male_tokens.txt" 100

ESPEAK_FILES=$(find "$VOICE_DIR/espeak-ng-data" -type f | wc -l | tr -d ' ')
if [ "$ESPEAK_FILES" -lt 50 ]; then
    echo "❌ espeak-ng-data incomplet ($ESPEAK_FILES fichiers)"
    exit 1
fi
echo "  ✓ espeak-ng-data : $ESPEAK_FILES fichiers"

echo ""
echo "✓ Voix françaises prêtes dans $VOICE_DIR"
du -sh "$VOICE_DIR" 2>/dev/null || true
