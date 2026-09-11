#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/dist"

if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [path-to-KeyboardFixer.app]" >&2
  exit 1
fi

if [[ $# -eq 1 ]]; then
  APP_PATH="$1"
else
  "$PROJECT_ROOT/scripts/build.sh"
  APP_PATH="$PROJECT_ROOT/build/Build/Products/Release/KeyboardFixer.app"
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "KeyboardFixer.app was not found at: $APP_PATH" >&2
  exit 1
fi

INFO_PLIST="$APP_PATH/Contents/Info.plist"
EXECUTABLE="$APP_PATH/Contents/MacOS/KeyboardFixer"

if [[ ! -f "$INFO_PLIST" || ! -x "$EXECUTABLE" ]]; then
  echo "The supplied path is not a complete KeyboardFixer.app bundle." >&2
  exit 1
fi

/usr/bin/codesign --verify --deep --strict "$APP_PATH"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
DMG_PATH="$OUTPUT_DIR/KeyboardFixer-v${VERSION}.dmg"
STAGING_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/KeyboardFixer-dmg.XXXXXX")"

cleanup() {
  /bin/rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

/bin/mkdir -p "$OUTPUT_DIR"
/usr/bin/ditto "$APP_PATH" "$STAGING_DIR/KeyboardFixer.app"
/usr/bin/ditto "$PROJECT_ROOT/INSTALLATION-TH.txt" "$STAGING_DIR/วิธีติดตั้ง.txt"
/bin/ln -s /Applications "$STAGING_DIR/Applications"

/usr/bin/hdiutil create \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  -fs HFS+ \
  -volname "KeyboardFixer ${VERSION}" \
  -srcfolder "$STAGING_DIR" \
  "$DMG_PATH"

/usr/bin/hdiutil verify "$DMG_PATH"

echo "Created: $DMG_PATH"
echo "Open the DMG, then drag KeyboardFixer.app onto Applications."
