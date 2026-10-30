#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
APP="dist/Brosyl Workshop Pricing Calculator.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/BrosylWorkshop" "$APP/Contents/MacOS/BrosylWorkshop"
cp -R "$BIN_DIR/BrosylWorkshop_BrosylApp.bundle" "$APP/Contents/Resources/"
cp Branding/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Brosyl Workshop Pricing Calculator</string>
<key>CFBundleDisplayName</key><string>Brosyl Workshop Pricing Calculator</string>
<key>CFBundleIdentifier</key><string>com.brosyl.workshop.pricing</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleVersion</key><string>2</string>
<key>CFBundleShortVersionString</key><string>1.0.1</string>
<key>CFBundleExecutable</key><string>BrosylWorkshop</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP"
echo "Built: $APP"
