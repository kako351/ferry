#!/bin/bash
set -e

swift build

APP_DIR=".build/debug/ADBDesktop.app/Contents/MacOS"
mkdir -p "$APP_DIR"

cp .build/debug/ADBDesktop "$APP_DIR/ADBDesktop"

# Info.plist（初回のみ）
PLIST=".build/debug/ADBDesktop.app/Contents/Info.plist"
if [ ! -f "$PLIST" ]; then
cat > "$PLIST" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ADBDesktop</string>
    <key>CFBundleIdentifier</key>
    <string>com.adbdesktop.app</string>
    <key>CFBundleName</key>
    <string>ADB Desktop</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
EOF
fi

pkill -f "ADBDesktop.app" 2>/dev/null || true
sleep 0.3
open .build/debug/ADBDesktop.app
