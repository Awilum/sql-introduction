#!/usr/bin/env bash

set -e

LOCALES=("ru")

# VERSION
VERSION=${1:-"dev"}

COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
BUILD_DATE=$(date '+%Y-%m-%d %H:%M:%S %Z')
REPO_URL="https://github.com/Awilum/sql-introduction"

echo "Building SQL Introduction..."
echo "Version: $VERSION"

for LOCALE in "${LOCALES[@]}"; do

  echo ""
  echo "=============================="
  echo "Building locale: $LOCALE"
  echo "=============================="

  OUT_DIR="output/$LOCALE"
  GEN_DIR="$LOCALE/book/generated"
  SRC_DIR="$LOCALE/book"

  mkdir -p "$OUT_DIR"
  mkdir -p "$GEN_DIR"

  # -------------------------
  # BUILD INFO (локализуемый блок)
  # -------------------------

  if [[ "$LOCALE" == "ru" ]]; then
    TITLE="Об издании"
    DESC_1="Перед вами экземпляр книги **SQL Введение**, собранный из исходного репозитория Git."
    DESC_2="Версия: **${VERSION}** (коммит **${COMMIT}**, ветка **${BRANCH}**). Дата сборки: ${BUILD_DATE}."
    DESC_3="Каждая сборка создаётся напрямую из исходного кода книги, что обеспечивает воспроизводимость версии."
    DESC_4="Исходный репозиторий: ${REPO_URL}"
  else
    TITLE="About this edition"
    DESC_1="This copy of **SQL Introduction** was generated from the Git repository."
    DESC_2="Version **${VERSION}** (commit **${COMMIT}**, branch **${BRANCH}**). Build date: ${BUILD_DATE}."
    DESC_3="Each build is reproducible and generated directly from source code."
    DESC_4="Repository: ${REPO_URL}"
  fi

  cat > "$GEN_DIR/00-build-info.md" <<EOF
# ${TITLE}

${DESC_1}

${DESC_2}

${DESC_3}

${DESC_4}
EOF

  # -------------------------
  # INPUT FILES
  # -------------------------

  SRC=(
    "$SRC_DIR/metadata.yaml"
    "$GEN_DIR/00-build-info.md"
    $SRC_DIR/chapters/*.md
  )
 
  RESOURCE_PATH="$SRC_DIR:$SRC_DIR/images:$SRC_DIR/chapters:$GEN_DIR"

  # -------------------------
  # PDF
  # -------------------------

  echo "Building PDF ($LOCALE)..."

  pandoc \
    "${SRC[@]}" \
    --resource-path="$RESOURCE_PATH" \
    --pdf-engine=typst \
    --template="$SRC_DIR/template.typ" \
    --toc \
    --number-sections \
    -o "$OUT_DIR/sql-introduction.pdf"

  # -------------------------
  # EPUB
  # -------------------------

  echo "Building EPUB ($LOCALE)..."

  pandoc \
    "$SRC_DIR/metadata.yaml" \
    "$GEN_DIR/00-build-info.md" \
    $SRC_DIR/chapters/*.md \
    --resource-path="$RESOURCE_PATH" \
    --toc \
    --number-sections \
    --epub-cover-image="$SRC_DIR/images/cover.png" \
    -o "$OUT_DIR/sql-introduction.epub"

  # -------------------------
  # CLEANUP
  # -------------------------

  rm -rf "$GEN_DIR"

  echo "Done locale: $LOCALE"

done

echo ""
echo "All builds completed!"