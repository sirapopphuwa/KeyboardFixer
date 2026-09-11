#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_PATH="$PROJECT_ROOT/build"

xcodebuild \
  -project "$PROJECT_ROOT/KeyboardFixer.xcodeproj" \
  -scheme KeyboardFixer \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build

APP_PATH="$(find "$DERIVED_DATA_PATH/Build/Products/Release" -maxdepth 1 -name 'KeyboardFixer.app' -type d -print -quit)"
if [[ -z "$APP_PATH" ]]; then
  echo "Build finished, but KeyboardFixer.app was not found." >&2
  exit 1
fi

# Keep a stable local designated requirement. This is important for macOS
# Accessibility authorization when development builds are rebuilt in place.
/usr/bin/codesign \
  --force \
  --sign - \
  --identifier com.keyboardfixer.KeyboardFixer \
  -r='designated => identifier "com.keyboardfixer.KeyboardFixer"' \
  "$APP_PATH"

echo "Built: $APP_PATH"
