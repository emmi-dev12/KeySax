#!/bin/bash
cd "$(dirname "$0")"
APP="KeySaxKeys.app"
if [[ ! -d "$APP" ]]; then
  echo "Put this script next to KeySaxKeys.app"
  read -r
  exit 1
fi
xattr -cr "$APP" 2>/dev/null || true
chmod +x "$APP/Contents/MacOS/KeySaxKeys"
open "$APP"
