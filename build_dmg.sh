#!/bin/bash

# Configuration
APP_NAME="LiveWallpaperPro"
BUILD_DIR=".build/arm64-apple-macosx/release"
DMG_NAME="LiveWallpaperPro_1.0.0.dmg"
APP_BUNDLE="dist/$APP_NAME.app"

echo "🚀 Starting Production Build (Zero-Drain Optimized)..."

# 1. Clean and Build
rm -rf .build
swift build -c release --arch arm64

if [ $? -ne 0 ]; then
    echo "❌ Error: Build failed"
    exit 1
fi

# 2. Construct .app bundle
echo "🏗️  Constructing .app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp ".build/arm64-apple-macosx/release/LiveWallpaperPro" "$APP_BUNDLE/Contents/MacOS/"

# Copy App Icon if exists
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
fi

# Create Info.plist if missing
if [ ! -f "$APP_BUNDLE/Contents/Info.plist" ]; then
cat <<EOF > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>LiveWallpaperPro</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.rinesh.LiveWallpaperPro</string>
    <key>CFBundleName</key>
    <string>LiveWallpaperPro</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF
fi

# 3. Create DMG
echo "📦 Packaging into DMG..."
rm -f "$DMG_NAME"
mkdir -p dist/dmg
cp -R "$APP_BUNDLE" dist/dmg/
ln -s /Applications dist/dmg/Applications

hdiutil create -volname "$APP_NAME" -srcfolder dist/dmg -ov -format UDZO "$DMG_NAME"

# 4. Cleanup
rm -rf dist/dmg

echo "✅ Build Complete: $DMG_NAME"
echo "🚀 Optimized for Zero-Drain performance."
