<p align="center">
  <img src="Screenshots/app_icon.png" width="128" height="128" alt="FreeSizeUp App Icon">
</p>

# 🖥️ FreeSizeUp

> **FreeSizeUp** 是一款高级、超轻量且完全原生的 macOS 窗口管理工具 —— 它被打造为 **SizeUp 的终极开源替代版本**。它 100% 还原了经典 SizeUp 的快捷键和布局操作，同时引入了现代化的视觉系统（包括相匹配的四个角落箭头视觉标识、交互式自定义分区滑块、屏幕边缘留白），并完全符合 Swift 6 的严格并发安全标准。

专注于原生性能和苹果高级设计美学，FreeSizeUp 允许您使用轻量的全局快捷键在多显示器和虚拟桌面之间瞬间分割、调整大小和移动窗口。

[🇺🇸 English Version (英文版)](README.md)

---

## 🎨 视觉预览

以下是现代化的用户界面、布局配置和动态系统托盘下拉菜单的预览：

| ⚙️ 通用设置与主题 | 🎛️ 统一快捷键配置 |
| :---: | :---: |
| ![General Settings](Screenshots/general_settings.png) | ![Shortcuts Panel](Screenshots/shortcuts_unified.png) |

| 🛠️ 高级设置 | 📲 原生菜单栏下拉框 |
| :---: | :---: |
| ![Advanced Settings](Screenshots/advanced_settings.png) | ![Menu Bar Dropdown](Screenshots/menu_bar_tray.png) |

---

## ✨ 核心功能

*   **⚡ 分屏与半屏**: 瞬间将窗口分割为左半屏、右半屏、上半屏或下半屏。
*   **📐 四分之一屏与角落**: 将窗口移动到左上角、右上角、左下角或右下角区域。
*   **🖥️ 多显示器支持**: 在多显示器间移动窗口，支持绝对边距和按比例缩放。
*   **🌌 虚拟桌面空间**: 模拟拖拽标题栏，完美实现窗口在 macOS 虚拟桌面间的移动（上一个桌面 / 下一个桌面）。
*   **⏪ 撤销 (SnapBack)**: 立即撤销上一次的窗口调整操作，恢复窗口之前的大小和位置。
*   **📊 自定义比例与边距**:
    *   **交互式边距**: 设置屏幕四周的像素边距，防止窗口覆盖菜单栏、程序坞或系统小组件。
    *   **交互式分屏滑块**: 实时预览并调整左右及上下分屏的百分比。
*   **🌟 拟物化毛玻璃 HUD 动画**: 触发快捷键时，屏幕中央会显示漂亮的半透明发光图标提示。
*   **🎙️ 智能快捷键录制**: 动态录制全局快捷键，自带防冲突的 SwiftUI 焦点取消界面。
*   **🌓 自适应外观**: 完全支持原生浅色模式、深色模式以及跟随系统主题。
*   **🛡️ Swift 6 准备就绪**: 零外部依赖，完全符合 Swift 6 严格并发检查标准。

---

## ⌨️ 默认快捷键

| 分类 | 动作 | 快捷键 |
| :--- | :--- | :--- |
| **分屏 (半屏)** | 左半屏 | `⌃ ⌥ ⌘ ←` (Ctrl + Opt + Cmd + 左箭头) |
| | 右半屏 | `⌃ ⌥ ⌘ →` (Ctrl + Opt + Cmd + 右箭头) |
| | 上半屏 | `⌃ ⌥ ⌘ ↑` (Ctrl + Opt + Cmd + 上箭头) |
| | 下半屏 | `⌃ ⌥ ⌘ ↓` (Ctrl + Opt + Cmd + 下箭头) |
| **四分之一屏 (角落)** | 左上角 | `⌃ ⌥ ⇧ ←` (Ctrl + Opt + Shift + 左箭头) |
| | 右上角 | `⌃ ⌥ ⇧ ↑` (Ctrl + Opt + Shift + 上箭头) |
| | 左下角 | `⌃ ⌥ ⇧ ↓` (Ctrl + Opt + Shift + 下箭头) |
| | 右下角 | `⌃ ⌥ ⇧ →` (Ctrl + Opt + Shift + 右箭头) |
| **显示器与桌面** | 上一个显示器 | `⌃ ⌥ ⌘ ,` (Ctrl + Opt + Cmd + 逗号) |
| | 下一个显示器 | `⌃ ⌥ ⌘ .` (Ctrl + Opt + Cmd + 句号) |
| | 上一个虚拟桌面 | `⌃ ⌥ ⌘ [` (Ctrl + Opt + Cmd + 左括号) |
| | 下一个虚拟桌面 | `⌃ ⌥ ⌘ ]` (Ctrl + Opt + Cmd + 右括号) |
| **系统调整** | 全屏 | `⌃ ⌥ ⌘ M` (Ctrl + Opt + Cmd + M) |
| | 居中窗口 | `⌃ ⌥ ⌘ C` (Ctrl + Opt + Cmd + C) |
| | 撤销 (SnapBack) | `⌃ ⌥ ⌘ /` (Ctrl + Opt + Cmd + 斜杠) |

---

## ⚙️ 安装与编译

### 环境要求
*   macOS 13.0 或更高版本 (Ventura / Sonoma / Sequoia)
*   Xcode 14.0+ 或命令行工具 (需包含 Swift 编译器)

### 🚀 自动化安装 (推荐)
对于未签名的开源应用，绕过苹果 Gatekeeper 隔离机制最简单的方法是使用我们提供的一键安装脚本。只需将此代码粘贴到您的终端中执行：

```bash
curl -sL https://raw.githubusercontent.com/wbangin/free-sizeup/main/install.sh | bash
```
此命令将安全地下载最新版本、解压到 `/Applications` 文件夹、移除系统的隔离属性限制，并自动为您启动应用程序。

---

### 📦 手动下载 DMG 安装包
1. 前往 [Releases 页面](https://github.com/wbangin/free-sizeup/releases) 并下载适用于您系统架构的 DMG 文件。
2. 打开 DMG 文件并将 `FreeSizeUp.app` 拖入您的 `/Applications` (应用程序) 文件夹中。
3. **针对 GitHub 下载包的重要提示**: 由于这是一款没有购买苹果付费开发者证书的免费开源软件，macOS 的 Gatekeeper 安全机制可能会拦截它，并提示 **"FreeSizeUp 已损坏，无法打开。您应该将它移到废纸篓。"** 
   要修复此问题，只需打开“终端 (Terminal)”并运行：
   ```bash
   xattr -cr /Applications/FreeSizeUp.app
   ```
   运行该命令后，您就可以正常打开该应用了。*(或者您也可以右键点击 DMG 里的 `Install.command` 选择“打开”来自动完成这些步骤)*

---

### 🔨 源码编译说明
1.  克隆或下载本仓库：
    ```bash
    git clone https://github.com/wbangin/free-sizeup.git
    cd free-sizeup
    ```
2.  编译并打包独立的 `.app` 文件：
    ```bash
    chmod +x build.sh
    ./build.sh
    ```
3.  启动应用程序：
    ```bash
    open FreeSizeUp.app
    ```

---

## 🔒 授予辅助功能权限

因为 macOS 保护安全偏好设置下的窗口控制权，所以 FreeSizeUp 需要 **辅助功能 (Accessibility) 权限** 才能与其他应用的窗口进行交互并调整它们的大小。

1.  第一次启动时，您会看到一个请求权限的弹窗。
2.  打开 ** -> 系统设置 -> 隐私与安全性 -> 辅助功能**。
3.  添加或将 **FreeSizeUp** 的开关切换为 **开启 (ON)**。
4.  FreeSizeUp 即可立即在您的菜单栏中开始工作！

---

## 🛠️ 技术架构栈

*   **UI 框架**: SwiftUI (偏好设置视图 & 快捷键录制器)
*   **事件处理**: Carbon Core 框架 (使用 `RegisterEventHotKey` 绑定系统级全局快捷键)
*   **窗口引擎**: ApplicationServices (使用 `AXUIElement` 辅助功能 API 实现高精度布局)
*   **隔离与线程安全**: 独立的 `@MainActor` 环境，完全符合 Swift 6 并发安全约束。

---

## ⚖️ Legal Disclaimer / 免责声明

**FreeSizeUp** is an independent, clean-room open-source project. 

* **No Affiliation**: This project is **not** affiliated, associated, authorized, endorsed by, or in any way officially connected with **Irradiated Software** or any of its subsidiaries or affiliates. The official SizeUp website can be found at [irradiatedsoftware.com/sizeup](https://www.irradiatedsoftware.com/sizeup/).
* **Trademarks**: "SizeUp" is a registered trademark of Irradiated Software. All other trademarks, service marks, and company names are the property of their respective owners. Their use in this project does not imply any affiliation with or endorsement by them.
* **No Warranty**: The software is provided "as is", without warranty of any kind, express or implied. Under no circumstances shall the authors or copyright holders be liable for any claims, damages, or other liabilities.

**FreeSizeUp** 是一个完全独立开发、从双零起步编写代码的纯原生开源项目。
* **无官方关联**：本开源项目与 **Irradiated Software** 官方无任何隶属、联合、授权、代言或官方关联。经典版 SizeUp 属于其原公司/作者所有。
* **商标声明**："SizeUp" 是 Irradiated Software 的注册商标。本仓库中对该商标的所有提及仅作为表明本应用的功能特征及“开源替代”定位之客观性技术参考，绝不构成任何商标侵权意图或官方关联暗示。
* **免责保证**：本软件按“原样”提供，不提供任何明示或暗示的保证（包括但不限于对特定用途的适用性和非侵权性的保证）。在任何情况下，作者或版权所有者均不对因本软件的使用而产生的任何索赔、损害或其他责任负责。

---

## 📄 开源许可证

本项目为开源项目，基于 [MIT License](LICENSE) 授权。
