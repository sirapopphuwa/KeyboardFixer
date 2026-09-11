#!/bin/bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIRECTORY="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
SOURCE_DIRECTORY="$PROJECT_DIRECTORY/KeyboardFixer-Windows"
OUTPUT_DIRECTORY="$PROJECT_DIRECTORY/build-windows"
ARCHIVE_PATH="$OUTPUT_DIRECTORY/KeyboardFixer-Windows-v1.0.0.zip"

mkdir -p "$OUTPUT_DIRECTORY"
rm -f "$ARCHIVE_PATH"
(
    cd "$PROJECT_DIRECTORY"
    /usr/bin/zip -r -q "$ARCHIVE_PATH" "$(basename "$SOURCE_DIRECTORY")" \
        -x '*.DS_Store' '*/._*' '__MACOSX/*'
)

echo "Windows package created:"
echo "$ARCHIVE_PATH"
