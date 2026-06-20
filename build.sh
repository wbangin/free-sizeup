#!/bin/bash
set -e

echo "🔨 Building FreeSizeUp..."

# 1. Compile in Release mode using Swift PM for both architectures if possible
echo "🏗️ Compiling for Apple Silicon (arm64)..."
swift build -c release --triple arm64-apple-macosx

echo "🏗️ Compiling for Intel (x86_64)..."
swift build -c release --triple x86_64-apple-macosx

# Setup bundle paths
APP_DIR="FreeSizeUp.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📂 Creating application bundle directory structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

if ls Resources/*.lproj 1> /dev/null 2>&1; then
    echo "🌐 Copying Localization bundles..."
    cp -R Resources/*.lproj "$RESOURCES_DIR/"
fi

if [ -f ".build/arm64-apple-macosx/release/FreeSizeUp" ] && [ -f ".build/x86_64-apple-macosx/release/FreeSizeUp" ]; then
    echo "🔗 Packaging architectures into Universal Binary..."
    mkdir -p .build/universal
    lipo -create \
      .build/arm64-apple-macosx/release/FreeSizeUp \
      .build/x86_64-apple-macosx/release/FreeSizeUp \
      -output .build/universal/FreeSizeUp
    BINARY_PATH=".build/universal/FreeSizeUp"
else
    echo "⚠️ Universal binary compilation not completed, building default host architecture..."
    swift build -c release
    BINARY_PATH="$(swift build -c release --show-bin-path)/FreeSizeUp"
fi

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
cp "$BINARY_PATH" "$MACOS_DIR/FreeSizeUp"


# 5. Create standard Info.plist configuration file
echo "📄 Writing Info.plist configuration..."
APP_VERSION="${VERSION:-1.2.0}"
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
    <string>$APP_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$APP_VERSION</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 wbangin. All rights reserved.</string>
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

echo "📄 Generating Install.command script for DMG..."
cat << 'EOF' > Install.command
#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "📦 Installing FreeSizeUp to /Applications..."
rm -rf /Applications/FreeSizeUp.app
cp -R "$DIR/FreeSizeUp.app" /Applications/
echo "🔓 Removing Gatekeeper quarantine attribute..."
xattr -cr /Applications/FreeSizeUp.app
echo "✅ Installation complete! Launching FreeSizeUp..."
open /Applications/FreeSizeUp.app
echo ""
echo "Press any key to close this window..."
read -n 1 -s
EOF
chmod +x Install.command

echo "✅ App bundle assembled successfully: FreeSizeUp.app"
echo "👉 You can run it by executing: open FreeSizeUp.app"
