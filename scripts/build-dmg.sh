#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/../releases"
DMG_PATH="$OUTPUT_DIR/KeyMate-1.0.3.dmg"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/shortcut-finder-dmg.XXXXXX")"

cleanup() { rm -rf "$STAGING_DIR"; }
trap cleanup EXIT

"$PROJECT_DIR/scripts/build-app.sh"
mkdir -p "$OUTPUT_DIR"
rm -f "$DMG_PATH"
cp -R "$PROJECT_DIR/../KeyMate.app" "$STAGING_DIR/KeyMate.app"
ln -s /Applications "$STAGING_DIR/Applications"
cat > "$STAGING_DIR/התקנה.txt" <<'EOF'
KeyMate — התקנה

1. גררו את KeyMate.app אל Applications.
2. פתחו את האפליקציה מתיקיית Applications.
3. סמל מקלדת יופיע בשורת התפריטים העליונה.

האפליקציה מתאימה ל־macOS 14 ומעלה, במחשבי Apple Silicon ו־Intel.
EOF
hdiutil create -volname "KeyMate" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"
hdiutil verify "$DMG_PATH"
printf 'Built: %s\n' "$DMG_PATH"
