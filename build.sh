#!/bin/bash
set -e

echo "🔨 Building FreeSizeUp..."

# 1. Compile in Release mode using Swift PM
swift build -c release

# 2. Setup bundle paths
APP_DIR="FreeSizeUp.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📂 Creating application bundle directory structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 3. Compile high-resolution AppIcon from Screenshots/app_icon.png if it exists
if [ -f "Screenshots/app_icon.png" ]; then
    echo "🎨 Compiling macOS squircle App Icon..."
    rm -rf FreeSizeUp.iconset
    mkdir -p FreeSizeUp.iconset
    sips -s format png -z 16 16     Screenshots/app_icon.png --out FreeSizeUp.iconset/icon_16x16.png > /dev/null 2>&1
    sips -s format png -z 32 32     Screenshots/app_icon.png --out FreeSizeUp.iconset/icon_16x16@2x.png > /dev/null 2>&1
    sips -s format png -z 32 32     Screenshots/app_icon.png --out FreeSizeUp.iconset/icon_32x32.png > /dev/null 2>&1
    sips -s format png -z 64 64     Screenshots/app_icon.png --out FreeSizeUp.iconset/icon_32x32@2x.png > /dev/null 2>&1
    sips -s format png -z 128 128   Screenshots/app_icon.png --out FreeSizeUp.iconset/icon_128x128.png > /dev/null 2>&1
    sips -s format png -z 256 256   Screenshots/app_icon.png --out FreeSizeUp.iconset/icon_128x128@2x.png > /dev/null 2>&1
    sips -s format png -z 256 256   Screenshots/app_icon.png --out FreeSizeUp.iconset/icon_256x256.png > /dev/null 2>&1
    sips -s format png -z 512 512   Screenshots/app_icon.png --out FreeSizeUp.iconset/icon_256x256@2x.png > /dev/null 2>&1
    sips -s format png -z 512 512   Screenshots/app_icon.png --out FreeSizeUp.iconset/icon_512x512.png > /dev/null 2>&1
    sips -s format png -z 1024 1024 Screenshots/app_icon.png --out FreeSizeUp.iconset/icon_512x512@2x.png > /dev/null 2>&1
    
    iconutil -c icns FreeSizeUp.iconset
    mv FreeSizeUp.icns "$RESOURCES_DIR/AppIcon.icns"
    rm -rf FreeSizeUp.iconset
fi

# 4. Copy executable binary to App Bundle
echo "🚀 Copying compiled executable to bundle..."
cp ".build/release/FreeSizeUp" "$MACOS_DIR/FreeSizeUp"

# 5. Create standard Info.plist configuration file
echo "📄 Writing Info.plist configuration..."
cat <<EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.robin.FreeSizeUp</string>
    <key>CFBundleName</key>
    <string>FreeSizeUp</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>FreeSizeUp</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF

echo "✅ App bundle assembled successfully: FreeSizeUp.app"
echo "👉 You can run it by executing: open FreeSizeUp.app"
