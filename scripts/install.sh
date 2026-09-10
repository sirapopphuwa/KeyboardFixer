#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$PROJECT_ROOT/scripts/build.sh"

APP_PATH="$(find "$PROJECT_ROOT/build/Build/Products/Release" -maxdepth 1 -name 'KeyboardFixer.app' -type d -print -quit)"
DESTINATION="/Applications/KeyboardFixer.app"

if [[ -w /Applications ]]; then
  /usr/bin/ditto "$APP_PATH" "$DESTINATION"
else
  echo "Administrator access is required to install in /Applications."
  /usr/bin/sudo /usr/bin/ditto "$APP_PATH" "$DESTINATION"
fi

echo "Installed: $DESTINATION"
echo "Launch KeyboardFixer from Applications, then look for its keyboard icon in the menu bar."
