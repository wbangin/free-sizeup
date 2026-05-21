import Cocoa
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var preferencesWindow: NSWindow?
    private var statusBarItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Set up global hotkey trigger actions
        HotkeyManager.shared.onHotkeyTriggered = { action in
            WindowManager.shared.performAction(action)
        }
        
        // Register default hotkeys initially
        HotkeyManager.shared.updateHotkeys()
        
        // 2. Load system appearance theme immediately
        Settings.shared.applyTheme()
        
        // 3. Set up System Status Menu Bar item
        setupStatusBarItem()
        
        // Sync status bar item visibility dynamically
        Settings.shared.$showInMenuBar
            .sink { [weak self] visible in
                self?.toggleStatusBarItem(visible: visible)
            }
            .store(in: &cancellables)
            
        // Sync active hotkeys list when global enable/disable switches change
        Settings.shared.$enableShortcuts
            .sink { _ in
                // Post shortcuts change notification to update active hotkeys
                NotificationCenter.default.post(name: .shortcutsChanged, object: nil)
            }
            .store(in: &cancellables)
        
        // 4. Trigger Preferences Window on startup if requested or if permissions are missing
        let hasPermissions = WindowManager.shared.checkAccessibilityPermissions(prompt: false)
        if !hasPermissions || Settings.shared.showPreferencesOnLaunch {
            showPreferences()
        }
        
        // Listen to permission denied alerts to prompt user
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAccessibilityDenied),
            name: .accessibilityDenied,
            object: nil
        )
    }
    
    @objc private func handleAccessibilityDenied() {
        showPreferences()
    }
    
    // MARK: - Menu Bar Status Item Setup
    
    private func setupStatusBarItem() {
        guard Settings.shared.showInMenuBar else { return }
        
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Use a modern, custom vector four-corner-arrows icon
        if let button = item.button {
            button.image = NSImage.createTrayIcon()
            button.image?.accessibilityDescription = "FreeSizeUp"
        }
        
        rebuildStatusMenu(for: item)
        
        statusBarItem = item
    }
    
    private func toggleStatusBarItem(visible: Bool) {
        if visible {
            if statusBarItem == nil {
                setupStatusBarItem()
            }
        } else {
            if let item = statusBarItem {
                NSStatusBar.system.removeStatusItem(item)
                statusBarItem = nil
            }
        }
    }
    
    // Dynamically rebuild the menu dropdown
    private func rebuildStatusMenu(for item: NSStatusItem) {
        let menu = NSMenu(title: "FreeSizeUp Menu")
        
        // 1. Disable shortcuts checkbox toggle
        let disableItem = NSMenuItem(title: "Disable Shortcuts", action: #selector(toggleShortcuts(_:)), keyEquivalent: "")
        disableItem.target = self
        disableItem.state = Settings.shared.enableShortcuts ? .off : .on
        if let icon = NSImage.createSchematicIcon(for: nil, systemSymbolName: "keyboard") {
            disableItem.image = icon
        }
        menu.addItem(disableItem)
        menu.addItem(NSMenuItem.separator())
        
        // 2. Custom action rows
        addActionItem(menu, title: "Left", action: .left)
        addActionItem(menu, title: "Right", action: .right)
        addActionItem(menu, title: "Up", action: .up)
        addActionItem(menu, title: "Down", action: .down)
        menu.addItem(NSMenuItem.separator())
        
        addActionItem(menu, title: "Upper Left", action: .upperLeft)
        addActionItem(menu, title: "Upper Right", action: .upperRight)
        addActionItem(menu, title: "Lower Left", action: .lowerLeft)
        addActionItem(menu, title: "Lower Right", action: .lowerRight)
        menu.addItem(NSMenuItem.separator())
        
        addActionItem(menu, title: "Full Screen", action: .fullScreen)
        addActionItem(menu, title: "Center", action: .center)
        menu.addItem(NSMenuItem.separator())
        
        addActionItem(menu, title: "SnapBack", action: .snapBack)
        menu.addItem(NSMenuItem.separator())
        
        addActionItem(menu, title: "Prev Monitor", action: .prevMonitor)
        addActionItem(menu, title: "Next Monitor", action: .nextMonitor)
        menu.addItem(NSMenuItem.separator())
        
        addActionItem(menu, title: "Space Prev", action: .spacePrev)
        addActionItem(menu, title: "Space Next", action: .spaceNext)
        menu.addItem(NSMenuItem.separator())
        
        // 3. System operations
        let aboutItem = NSMenuItem(title: "About FreeSizeUp", action: #selector(showAboutPanel), keyEquivalent: "")
        aboutItem.target = self
        if let icon = NSImage.createSchematicIcon(for: nil, systemSymbolName: "info.circle") {
            aboutItem.image = icon
        }
        menu.addItem(aboutItem)
        
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferencesMenu), keyEquivalent: ",")
        preferencesItem.target = self
        if let icon = NSImage.createSchematicIcon(for: nil, systemSymbolName: "gearshape") {
            preferencesItem.image = icon
        }
        menu.addItem(preferencesItem)
        
        let quitItem = NSMenuItem(title: "Quit FreeSizeUp", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        if let icon = NSImage.createSchematicIcon(for: nil, systemSymbolName: "power") {
            quitItem.image = icon
        }
        menu.addItem(quitItem)
        
        item.menu = menu
    }
    
    private func addActionItem(_ menu: NSMenu, title: String, action: WindowAction) {
        let item = NSMenuItem(title: title, action: #selector(triggerAction(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = action
        
        // Attach hotkey symbol preview to menu item if registered
        if let shortcut = Settings.shared.shortcuts[action] as? KeyShortcut {
            item.keyEquivalent = KeyShortcut.keyName(for: shortcut.keyCode).lowercased()
            item.keyEquivalentModifierMask = shortcut.modifierFlags
        }
        
        if let icon = NSImage.createSchematicIcon(for: action) {
            item.image = icon
        }
        
        menu.addItem(item)
    }
    
    @objc private func toggleShortcuts(_ sender: NSMenuItem) {
        Settings.shared.enableShortcuts.toggle()
        sender.state = Settings.shared.enableShortcuts ? .off : .on
        
        // Rebuild menus to update keyEquivalent modifiers correctly
        if let item = statusBarItem {
            rebuildStatusMenu(for: item)
        }
    }
    
    @objc private func triggerAction(_ sender: NSMenuItem) {
        guard let action = sender.representedObject as? WindowAction else { return }
        WindowManager.shared.performAction(action)
    }
    
    @objc private func showAboutPanel() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
    }
    
    @objc private func openPreferencesMenu() {
        showPreferences()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Preferences Window management
    
    func showPreferences() {
        if preferencesWindow == nil {
            let view = PreferencesView()
            let hostingController = NSHostingController(rootView: view)
            
            // Standard titlebar integration following HIG rules
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 720, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            
            window.title = "FreeSizeUp Preferences"
            window.contentViewController = hostingController
            window.isReleasedWhenClosed = false
            window.center()
            
            // Custom appearance support matching Settings.shared.theme
            Settings.shared.applyTheme()
            
            preferencesWindow = window
        }
        
        // Activate app window hierarchy before ordering front to avoid background block
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindow?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - NSImage Extension for Custom Schematic Badges
extension NSImage {
    static func createSchematicIcon(for action: WindowAction?, systemSymbolName: String? = nil) -> NSImage? {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: true) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            
            // 1. Draw rounded rectangle background (light blue opacity 0.12)
            let bgPath = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
            NSColor(calibratedRed: 0.0, green: 0.48, blue: 1.0, alpha: 0.12).setFill()
            bgPath.fill()
            
            // Determine if it's a layout action or symbolic
            if let act = action {
                switch act {
                case .left, .right, .up, .down, .upperLeft, .upperRight, .lowerLeft, .lowerRight, .fullScreen, .center:
                    // 2. Outer window representation outline
                    let fW: CGFloat = 11.0
                    let fH: CGFloat = 11.0
                    let frameRect = NSRect(x: (rect.width - fW) / 2, y: (rect.height - fH) / 2, width: fW, height: fH)
                    let framePath = NSBezierPath(roundedRect: frameRect, xRadius: 2.2, yRadius: 2.2)
                    NSColor.systemBlue.setStroke()
                    framePath.lineWidth = 1.0
                    framePath.stroke()
                    
                    // 3. Filled region based on action, clipped inside the frame
                    context.saveGState()
                    let clipPath = NSBezierPath(roundedRect: frameRect.insetBy(dx: 0.5, dy: 0.5), xRadius: 1.7, yRadius: 1.7)
                    clipPath.addClip()
                    
                    NSColor.systemBlue.setFill()
                    let halfW = frameRect.width * 0.5
                    let halfH = frameRect.height * 0.5
                    
                    switch act {
                    case .left:
                        NSBezierPath(rect: NSRect(x: frameRect.minX, y: frameRect.minY, width: halfW, height: frameRect.height)).fill()
                    case .right:
                        NSBezierPath(rect: NSRect(x: frameRect.minX + halfW, y: frameRect.minY, width: halfW, height: frameRect.height)).fill()
                    case .up:
                        NSBezierPath(rect: NSRect(x: frameRect.minX, y: frameRect.minY, width: frameRect.width, height: halfH)).fill()
                    case .down:
                        NSBezierPath(rect: NSRect(x: frameRect.minX, y: frameRect.minY + halfH, width: frameRect.width, height: halfH)).fill()
                    case .upperLeft:
                        NSBezierPath(rect: NSRect(x: frameRect.minX, y: frameRect.minY, width: halfW, height: halfH)).fill()
                    case .upperRight:
                        NSBezierPath(rect: NSRect(x: frameRect.minX + halfW, y: frameRect.minY, width: halfW, height: halfH)).fill()
                    case .lowerLeft:
                        NSBezierPath(rect: NSRect(x: frameRect.minX, y: frameRect.minY + halfH, width: halfW, height: halfH)).fill()
                    case .lowerRight:
                        NSBezierPath(rect: NSRect(x: frameRect.minX + halfW, y: frameRect.minY + halfH, width: halfW, height: halfH)).fill()
                    case .fullScreen:
                        NSBezierPath(rect: frameRect).fill()
                    case .center:
                        let cW: CGFloat = 4.5
                        let cH: CGFloat = 4.5
                        let cRect = NSRect(x: frameRect.minX + (frameRect.width - cW) / 2, y: frameRect.minY + (frameRect.height - cH) / 2, width: cW, height: cH)
                        NSBezierPath(rect: cRect).fill()
                    default:
                        break
                    }
                    context.restoreGState()
                    
                default:
                    // Symbol actions: snapBack, prevMonitor, nextMonitor, spacePrev, spaceNext
                    let symbolName: String
                    switch act {
                    case .snapBack: symbolName = "arrow.uturn.backward"
                    case .prevMonitor: symbolName = "arrow.left.square.fill"
                    case .nextMonitor: symbolName = "arrow.right.square.fill"
                    case .spacePrev: symbolName = "arrow.left.to.line"
                    case .spaceNext: symbolName = "arrow.right.to.line"
                    default: symbolName = "questionmark"
                    }
                    drawSymbol(symbolName, in: rect, context: context)
                }
            } else if let symbolName = systemSymbolName {
                drawSymbol(symbolName, in: rect, context: context)
            }
            
            return true
        }
        
        return image
    }
    
    private static func drawSymbol(_ symbolName: String, in rect: NSRect, context: CGContext) {
        guard let symbolImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else { return }
        symbolImage.isTemplate = true
        
        let symbolSize: NSSize
        if symbolName.contains("square.fill") {
            symbolSize = NSSize(width: 9.5, height: 9.5)
        } else if symbolName.contains("keyboard") || symbolName.contains("gearshape") || symbolName.contains("power") {
            symbolSize = NSSize(width: 10, height: 10)
        } else {
            symbolSize = NSSize(width: 9, height: 9)
        }
        
        let targetRect = NSRect(
            x: (rect.width - symbolSize.width) / 2,
            y: (rect.height - symbolSize.height) / 2,
            width: symbolSize.width,
            height: symbolSize.height
        )
        
        let tintedSymbol = symbolImage.tinted(with: .systemBlue)
        tintedSymbol.draw(in: targetRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }
    
    func tinted(with color: NSColor) -> NSImage {
        let tinted = NSImage(size: self.size, flipped: false) { rect in
            color.set()
            NSBezierPath(rect: rect).fill()
            self.draw(in: rect, from: .zero, operation: .destinationIn, fraction: 1.0)
            return true
        }
        tinted.isTemplate = false
        return tinted
    }
    
    static func createTrayIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: true) { rect in
            // Ensure we have a graphics context
            guard NSGraphicsContext.current?.cgContext != nil else { return false }
            
            // 1. Draw in solid black (automatically tinted to white/black by macOS as a template image)
            NSColor.black.setStroke()
            NSColor.black.setFill()
            
            // Central window/square outline (black)
            let centerRect = NSRect(x: 6.5, y: 6.5, width: 5, height: 5)
            let centerPath = NSBezierPath(rect: centerRect)
            centerPath.lineWidth = 1.2
            centerPath.stroke()
            
            // Helper to draw a line segment in black
            func drawLine(from start: NSPoint, to end: NSPoint) {
                let path = NSBezierPath()
                path.move(to: start)
                path.line(to: end)
                path.lineWidth = 1.2
                path.lineCapStyle = .round
                path.stroke()
            }
            
            // Top‑Left arrow (pointing outward)
            drawLine(from: NSPoint(x: 6.5, y: 6.5), to: NSPoint(x: 3.0, y: 3.0))
            drawLine(from: NSPoint(x: 3.0, y: 3.0), to: NSPoint(x: 5.0, y: 3.0))
            drawLine(from: NSPoint(x: 3.0, y: 3.0), to: NSPoint(x: 3.0, y: 5.0))
            
            // Top‑Right arrow
            drawLine(from: NSPoint(x: 11.5, y: 6.5), to: NSPoint(x: 15.0, y: 3.0))
            drawLine(from: NSPoint(x: 15.0, y: 3.0), to: NSPoint(x: 13.0, y: 3.0))
            drawLine(from: NSPoint(x: 15.0, y: 3.0), to: NSPoint(x: 15.0, y: 5.0))
            
            // Bottom‑Left arrow
            drawLine(from: NSPoint(x: 6.5, y: 11.5), to: NSPoint(x: 3.0, y: 15.0))
            drawLine(from: NSPoint(x: 3.0, y: 15.0), to: NSPoint(x: 5.0, y: 15.0))
            drawLine(from: NSPoint(x: 3.0, y: 15.0), to: NSPoint(x: 3.0, y: 13.0))
            
            // Bottom‑Right arrow
            drawLine(from: NSPoint(x: 11.5, y: 11.5), to: NSPoint(x: 15.0, y: 15.0))
            drawLine(from: NSPoint(x: 15.0, y: 15.0), to: NSPoint(x: 13.0, y: 15.0))
            drawLine(from: NSPoint(x: 15.0, y: 15.0), to: NSPoint(x: 15.0, y: 13.0))
            
            return true
        }
        // Treat as a template so it gets macOS system adaptive styling
        image.isTemplate = true
        return image
    }
}
