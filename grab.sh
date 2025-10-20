#!/bin/bash
# download_chapter_pdf_all.sh
# Usage: ./download_chapter_pdf_all.sh <numero_du_chapitre>

BASE_URL="https://s22.anime-sama.me/s1/scans/One%20Piece/"
UA="Mozilla/5.0 (X11; Linux x86_64)"

if [ -z "$1" ]; then
  echo "Usage: $0 <numero_du_chapitre>"
  exit 1
fi

CHAP="$1"
CHAP_URL="${BASE_URL}/${CHAP}/"
OUT_DIR="${CHAP}"

mkdir -p "$OUT_DIR"

echo "📥 Téléchargement des images depuis : $CHAP_URL"
echo "📁 Destination : $OUT_DIR/"

# --- Récupère la liste des images ---
IMAGES=$(curl -s -A "$UA" "$CHAP_URL" \
  | grep -Eo 'href="[^"]+\.(jpg|jpeg|png|gif|webp|avif|bmp)"' \
  | sed 's/href="//;s/"$//' \
  | sort -V)

if [ -z "$IMAGES" ]; then
  echo "❌ Aucune image trouvée à $CHAP_URL"
  exit 1
fi

# --- Télécharge chaque image ---
for img in $IMAGES; do
    
    filename=$(basename "$img")
    url="${CHAP_URL}${filename}"
    echo "➡️ Téléchargement : $filename"
    echo "➡️ URL : $url"
    wget -O "${OUT_DIR}/${filename}" "$url"
done


# --- Convertit les images en PNG et crée le PDF ---
PDF_FILE="${CHAP}.pdf"
TEMP_DIR="temp_png_${CHAP}"
mkdir -p "$TEMP_DIR"

echo
echo "📄 Conversion des images en PNG pour le PDF..."

for img in $(ls "$OUT_DIR" | sort -V); do
  if identify "$OUT_DIR/$img" >/dev/null 2>&1; then
      magick "$OUT_DIR/$img" "${TEMP_DIR}/${img%.*}.png"
  else
      echo "⚠️ Ignoré (non image) : $img"
  fi
done


# Création du PDF depuis les images triées
img2pdf $(ls "$OUT_DIR" | sort -V | sed "s|^|$OUT_DIR/|") -o "${CHAP}.pdf"


# Nettoyage
rm -r "$TEMP_DIR"
rm -r "$CHAP"
echo
echo "✅ PDF créé : $PDF_FILE avec $(ls "$OUT_DIR" | wc -l) pages"

