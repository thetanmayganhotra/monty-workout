#!/bin/bash
# Builds MontyWorkout.app and packages it into a distributable .dmg.
set -euo pipefail
cd "$(dirname "$0")"

./build-app.sh

APP="MontyWorkout.app"
DMG="MontyWorkout.dmg"
VOL="Monty Workout"
STAGE="$(mktemp -d)"

echo "▸ Staging disk image…"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
# Custom volume icon for the mounted disk (best effort).
if [ -f Icon/AppIcon.icns ] && command -v SetFile >/dev/null 2>&1; then
  cp Icon/AppIcon.icns "$STAGE/.VolumeIcon.icns"
  SetFile -a C "$STAGE" || true
fi

rm -f "$DMG"
hdiutil create \
  -volname "$VOL" \
  -srcfolder "$STAGE" \
  -fs HFS+ \
  -format UDZO \
  -ov \
  "$DMG" >/dev/null

rm -rf "$STAGE"

echo "▸ Built $DMG ($(du -h "$DMG" | cut -f1))"
echo "  Open it, then drag Monty Workout into Applications."
echo
echo "  First launch (unsigned app): right-click the app ▸ Open ▸ Open,"
echo "  or run:  xattr -dr com.apple.quarantine /Applications/MontyWorkout.app"
