#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/KeySax"
OUT="${1:-$ROOT/build/KeySax.app}"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
PLUGIN_PATH="$(xcrun --find swiftc | xargs dirname)/../lib/swift/host/plugins"
MIN=27.0
CONFIG="${KEYSX_CONFIG:-release}"

mkdir -p "$OUT/Contents/MacOS" "$OUT/Contents/Resources"

SWIFT_FILES=("${(@f)$(find "$SRC" -name '*.swift' | sort)}")

ARCHS=(arm64)
if [[ "${KEYSX_UNIVERSAL:-1}" == "1" ]]; then
  ARCHS=(arm64 x86_64)
fi

OPT=(-O)
if [[ "$CONFIG" == "debug" ]]; then
  OPT=(-Onone -g -DDEBUG)
fi

BINARIES=()
for ARCH in $ARCHS; do
  BIN="/tmp/KeySax-$ARCH"
  echo "Compiling $ARCH…"
  swiftc \
    -parse-as-library \
    "${OPT[@]}" \
    -plugin-path "$PLUGIN_PATH" \
    -target "${ARCH}-apple-macosx${MIN}" \
    -sdk "$SDK" \
    -framework SwiftUI \
    -framework AppKit \
    -framework AVFoundation \
    -framework CoreMIDI \
    -framework Accelerate \
    -framework AudioToolbox \
    -framework CoreAudio \
    -framework UniformTypeIdentifiers \
    -framework Carbon \
    -o "$BIN" \
    "${SWIFT_FILES[@]}"
  BINARIES+=("$BIN")
done

if [[ ${#BINARIES[@]} -eq 1 ]]; then
  cp "${BINARIES[1]}" "$OUT/Contents/MacOS/KeySax"
else
  lipo -create -output "$OUT/Contents/MacOS/KeySax" "${BINARIES[@]}"
fi

cp "$SRC/Info.plist" "$OUT/Contents/Info.plist"
cp "$SRC/Resources/AppIcon.icns" "$OUT/Contents/Resources/AppIcon.icns"
echo -n "APPL????" > "$OUT/Contents/PkgInfo"

/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable KeySax" "$OUT/Contents/Info.plist" >/dev/null
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$OUT/Contents/Info.plist" >/dev/null

codesign --force --sign - --timestamp=none "$OUT" >/dev/null

echo "Built $OUT"
file "$OUT/Contents/MacOS/KeySax"
