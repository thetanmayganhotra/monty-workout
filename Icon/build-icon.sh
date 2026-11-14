#!/bin/bash
# Renders the app icon (Icon/make-icon.swift) and packs it into Icon/AppIcon.icns.
set -euo pipefail
cd "$(dirname "$0")"

TMP="$(mktemp -d)"
cp make-icon.swift "$TMP/main.swift"
swiftc -O "$TMP/main.swift" ../Sources/MontyWorkout/Model/StickFigure.swift -o "$TMP/make-icon"
"$TMP/make-icon" coral "$TMP/icon_1024.png" >/dev/null

SET="$TMP/AppIcon.iconset"
mkdir -p "$SET"
for s in 16 32 128 256 512; do
  sips -z $s $s         "$TMP/icon_1024.png" --out "$SET/icon_${s}x${s}.png"    >/dev/null
  sips -z $((s*2)) $((s*2)) "$TMP/icon_1024.png" --out "$SET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$SET" -o AppIcon.icns
cp "$TMP/icon_1024.png" AppIcon.png
rm -rf "$TMP"
echo "▸ Icon/AppIcon.icns ready"
