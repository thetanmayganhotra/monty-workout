#!/bin/bash
# Builds MontyWorkout.app — a double-clickable macOS app bundle.
set -euo pipefail
cd "$(dirname "$0")"

echo "▸ Building release binary…"
swift build -c release

BIN=".build/release/MontyWorkout"
APP="MontyWorkout.app"
CONTENTS="$APP/Contents"

rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BIN" "$CONTENTS/MacOS/MontyWorkout"
[ -f Icon/AppIcon.icns ] || ./Icon/build-icon.sh
cp Icon/AppIcon.icns "$CONTENTS/Resources/AppIcon.icns"

# Pre-recorded neural voice clips (see Voice/).
if [ -d Voice/clips ]; then
  mkdir -p "$CONTENTS/Resources/Voice"
  cp Voice/clips/*.mp3 "$CONTENTS/Resources/Voice/"
fi

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>              <string>Monty Workout</string>
  <key>CFBundleDisplayName</key>       <string>Monty Workout</string>
  <key>CFBundleIdentifier</key>        <string>com.monty.workout</string>
  <key>CFBundleVersion</key>           <string>1</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundlePackageType</key>       <string>APPL</string>
  <key>CFBundleExecutable</key>        <string>MontyWorkout</string>
  <key>CFBundleIconFile</key>          <string>AppIcon</string>
  <key>LSMinimumSystemVersion</key>    <string>14.0</string>
  <key>NSHighResolutionCapable</key>   <true/>
  <key>LSApplicationCategoryType</key> <string>public.app-category.healthcare-fitness</string>
</dict>
</plist>
PLIST

# Ad-hoc sign so Gatekeeper lets it run locally without fuss.
codesign --force --sign - "$APP" >/dev/null 2>&1 || true

echo "▸ Built $APP"
echo "  Run it:      open $APP"
echo "  Install it:  cp -r $APP /Applications/"
