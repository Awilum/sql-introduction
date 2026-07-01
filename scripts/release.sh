#!/usr/bin/env bash

set -euo pipefail

VERSION=${1:-}

if [[ -z "$VERSION" ]]; then
    echo "Usage:"
    echo "  ./scripts/release.sh v1.0.0"
    exit 1
fi

echo "🚀 Starting release $VERSION"

########################################
# Sanity checks
########################################

if ! git diff --quiet; then
    echo "❌ Working directory has uncommitted changes."
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "❌ GitHub CLI (gh) is not installed."
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "❌ You are not logged into GitHub CLI."
    echo "Run:"
    echo "    gh auth login"
    exit 1
fi

########################################
# Build
########################################

echo "📦 Building book..."

./scripts/build.sh "$VERSION"

########################################
# Collect artifacts
########################################

RELEASE_DIR="release/$VERSION"

rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

find output -type f -name "*.pdf" -exec cp {} "$RELEASE_DIR" \;
find output -type f -name "*.epub" -exec cp {} "$RELEASE_DIR" \;

if ! ls "$RELEASE_DIR"/*.pdf >/dev/null 2>&1; then
    echo "❌ No PDF files found."
    exit 1
fi

if ! ls "$RELEASE_DIR"/*.epub >/dev/null 2>&1; then
    echo "❌ No EPUB files found."
    exit 1
fi

echo
echo "Artifacts:"
ls -lh "$RELEASE_DIR"

########################################
# Create git tag
########################################

if git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo "❌ Tag '$VERSION' already exists."
    exit 1
fi

echo
echo "🏷 Creating tag..."

git tag "$VERSION"
git push origin "$VERSION"

########################################
# Create GitHub Release
########################################

echo
echo "🐙 Creating GitHub Release..."

gh release create "$VERSION" \
    "$RELEASE_DIR"/*.pdf \
    "$RELEASE_DIR"/*.epub \
    --title "$VERSION" \
    --generate-notes

echo
echo "✅ Release created successfully!"

echo
echo "Release page:"
gh release view "$VERSION" --web