#!/bin/bash

set -e

echo "=========================================="
echo "🚀 Installing FreeSizeUp (macOS Window Manager)"
echo "=========================================="
echo ""

echo "📥 Downloading latest FreeSizeUp release..."
TEMP_DMG=$(mktemp /tmp/FreeSizeUp.XXXXXX.dmg)
curl -L -# "https://github.com/wbangin/free-sizeup/releases/latest/download/FreeSizeUp-Universal.dmg" -o "$TEMP_DMG"

echo "💿 Mounting DMG..."
MOUNT_DIR=$(mktemp -d /tmp/FreeSizeUpMount.XXXXXX)
hdiutil attach "$TEMP_DMG" -mountpoint "$MOUNT_DIR" -quiet -nobrowse

echo "📦 Installing to /Applications..."
# Remove old version if it exists
if [ -d "/Applications/FreeSizeUp.app" ]; then
    rm -rf "/Applications/FreeSizeUp.app"
fi
cp -R "$MOUNT_DIR/FreeSizeUp.app" /Applications/

echo "🔓 Bypassing Gatekeeper (removing quarantine attribute)..."
xattr -cr /Applications/FreeSizeUp.app

echo "⏏️ Cleaning up..."
hdiutil detach "$MOUNT_DIR" -quiet
rm -f "$TEMP_DMG"
rm -rf "$MOUNT_DIR"

echo "✅ Installation complete!"
echo "✨ Launching FreeSizeUp..."
open /Applications/FreeSizeUp.app

echo ""
echo "Please look for the FreeSizeUp icon in your menu bar."
echo "If this is your first time running the app, it will prompt you for Accessibility Permissions."
echo "=========================================="
