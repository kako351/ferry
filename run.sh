#!/bin/bash
set -e

swift build

APP_DIR=".build/debug/Ferry.app/Contents/MacOS"
mkdir -p "$APP_DIR"

cp .build/debug/Ferry "$APP_DIR/Ferry"

# Info.plist（初回のみ）
PLIST=".build/debug/Ferry.app/Contents/Info.plist"
if [ ! -f "$PLIST" ]; then
cat > "$PLIST" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Ferry</string>
    <key>CFBundleIdentifier</key>
    <string>com.ferry.app</string>
    <key>CFBundleName</key>
    <string>Ferry</string>
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

pkill -f "Ferry.app" 2>/dev/null || true
sleep 0.3
open .build/debug/Ferry.app
