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
