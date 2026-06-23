#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Detect system language
LANG_CODE=$(defaults read -g AppleLocale 2>/dev/null | cut -d'_' -f1)

if [ "$LANG_CODE" = "zh" ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║        📦 FreeSizeUp 安装程序                    ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    echo "➜ 正在将 FreeSizeUp.app 安装到 /Applications ..."
    rm -rf /Applications/FreeSizeUp.app
    cp -R "$DIR/FreeSizeUp.app" /Applications/
    echo "➜ 正在移除 Gatekeeper 隔离属性 (解决「文件已损坏」问题)..."
    xattr -cr /Applications/FreeSizeUp.app
    echo ""
    echo "✅ 安装完成！正在启动 FreeSizeUp..."
    open /Applications/FreeSizeUp.app
    echo ""
    echo "按任意键关闭此窗口..."
    read -n 1 -s
else
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║        📦 FreeSizeUp Installer                  ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    echo "➜ Installing FreeSizeUp.app to /Applications ..."
    rm -rf /Applications/FreeSizeUp.app
    cp -R "$DIR/FreeSizeUp.app" /Applications/
    echo "➜ Removing Gatekeeper quarantine attribute..."
    xattr -cr /Applications/FreeSizeUp.app
    echo ""
    echo "✅ Installation complete! Launching FreeSizeUp..."
    open /Applications/FreeSizeUp.app
    echo ""
    echo "Press any key to close this window..."
    read -n 1 -s
fi
