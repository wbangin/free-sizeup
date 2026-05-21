import Cocoa
import ApplicationServices

@MainActor
class WindowManager {
    static let shared = WindowManager()
    
    // SnapBack History: Store previous frames mapped by window identifier (CFHash string)
    private var snapBackHistory: [String: CGRect] = [:]
    private let maxHistoryCount = 20
    
    private init() {}
    
    // Check if the application currently has Accessibility permissions
    func checkAccessibilityPermissions(prompt: Bool) -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": prompt]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // Main action coordinator called by hotkeys
    func performAction(_ action: WindowAction) {
        guard checkAccessibilityPermissions(prompt: false) else {
            print("FreeSizeUp: Cannot perform action, accessibility permissions not granted.")
            // Post a notification to show the permissions helper view
            NotificationCenter.default.post(name: .accessibilityDenied, object: nil)
            return
        }
        
        // 1. Get the frontmost window
        guard let window = getFrontmostWindow() else {
            print("FreeSizeUp: No active window found.")
            return
        }
        
        // 2. Fetch current window frame
        guard let currentFrame = getWindowFrame(window) else {
            print("FreeSizeUp: Failed to get current window frame.")
            return
        }
        
        let primaryHeight = NSScreen.screens[0].frame.height
        
        // 3. Find the screen containing the window
        guard let screen = getScreenForWindowFrame(currentFrame, primaryScreenHeight: primaryHeight) else {
            print("FreeSizeUp: Could not find screen for window.")
            return
        }
        
        // Get the window identifier for SnapBack history
        let windowId = getWindowIdentifier(window)
        
        // 4. Handle SnapBack action specifically
        if action == .snapBack {
            if let previousFrame = snapBackHistory[windowId] {
                // Restore frame
                setWindowFrame(window, frame: previousFrame)
                snapBackHistory.removeValue(forKey: windowId)
                
                // Show HUD feedback
                NotificationCenter.default.post(name: .showOverlayHUD, object: nil, userInfo: ["action": action])
            } else {
                print("FreeSizeUp: No SnapBack history for this window.")
            }
            return
        }
        
        // Record SnapBack history before modifying the window frame
        snapBackHistory[windowId] = currentFrame
        if snapBackHistory.count > maxHistoryCount {
            // Trim old records
            if let firstKey = snapBackHistory.keys.first {
                snapBackHistory.removeValue(forKey: firstKey)
            }
        }
        
        // 5. Handle Spaces actions specifically
        if action == .spacePrev || action == .spaceNext {
            performSpaceMove(window, frame: currentFrame, action: action)
            return
        }
        
        // 6. Compute Target Rect based on Action
        let targetRect: CGRect
        let settings = Settings.shared
        
        // Calculate screen frame converted to accessibility top-left origin
        let visFrame = accessibilityRect(for: screen.visibleFrame, primaryScreenHeight: primaryHeight)
        
        // Apply margins
        let usableX = visFrame.minX + CGFloat(settings.marginLeft)
        let usableY = visFrame.minY + CGFloat(settings.marginTop)
        let usableWidth = max(100, visFrame.width - CGFloat(settings.marginLeft + settings.marginRight))
        let usableHeight = max(100, visFrame.height - CGFloat(settings.marginTop + settings.marginBottom))
        
        let splitLR = settings.partitionLeftRight
        let splitTB = settings.partitionTopBottom
        
        switch action {
        case .left:
            targetRect = CGRect(x: usableX, y: usableY, width: usableWidth * splitLR, height: usableHeight)
            
        case .right:
            targetRect = CGRect(x: usableX + usableWidth * splitLR, y: usableY, width: usableWidth * (1.0 - splitLR), height: usableHeight)
            
        case .up:
            targetRect = CGRect(x: usableX, y: usableY, width: usableWidth, height: usableHeight * splitTB)
            
        case .down:
            targetRect = CGRect(x: usableX, y: usableY + usableHeight * splitTB, width: usableWidth, height: usableHeight * (1.0 - splitTB))
            
        case .upperLeft:
            targetRect = CGRect(x: usableX, y: usableY, width: usableWidth * splitLR, height: usableHeight * splitTB)
            
        case .upperRight:
            targetRect = CGRect(x: usableX + usableWidth * splitLR, y: usableY, width: usableWidth * (1.0 - splitLR), height: usableHeight * splitTB)
            
        case .lowerLeft:
            targetRect = CGRect(x: usableX, y: usableY + usableHeight * splitTB, width: usableWidth * splitLR, height: usableHeight * (1.0 - splitTB))
            
        case .lowerRight:
            targetRect = CGRect(x: usableX + usableWidth * splitLR, y: usableY + usableHeight * splitTB, width: usableWidth * (1.0 - splitLR), height: usableHeight * (1.0 - splitTB))
            
        case .fullScreen:
            targetRect = CGRect(x: usableX, y: usableY, width: usableWidth, height: usableHeight)
            
        case .center:
            // Custom center sizing configurations
            let width: CGFloat
            let height: CGFloat
            
            // Check absolute vs relative resizing flags
            let centerAndResize = UserDefaults.standard.bool(forKey: "centerAndResize") // Match details
            if centerAndResize {
                let absolute = UserDefaults.standard.bool(forKey: "centerAbsolute")
                if absolute {
                    let w = CGFloat(UserDefaults.standard.integer(forKey: "centerAbsoluteWidth"))
                    let h = CGFloat(UserDefaults.standard.integer(forKey: "centerAbsoluteHeight"))
                    width = w > 0 ? w : 800
                    height = h > 0 ? h : 600
                } else {
                    let pw = UserDefaults.standard.double(forKey: "centerRelativeWidth")
                    let ph = UserDefaults.standard.double(forKey: "centerRelativeHeight")
                    let pctW = pw > 0 ? pw : 0.75
                    let pctH = ph > 0 ? ph : 0.75
                    width = usableWidth * CGFloat(pctW)
                    height = usableHeight * CGFloat(pctH)
                }
            } else {
                width = currentFrame.width
                height = currentFrame.height
            }
            
            targetRect = CGRect(
                x: usableX + (usableWidth - width) / 2.0,
                y: usableY + (usableHeight - height) / 2.0,
                width: width,
                height: height
            )
            
        case .prevMonitor, .nextMonitor:
            targetRect = computeMonitorShift(currentFrame, action: action, primaryScreenHeight: primaryHeight)
            
        default:
            return
        }
        
        // 7. Apply target rect to window
        setWindowFrame(window, frame: targetRect)
        
        // Post notification for visual action overlay HUD
        NotificationCenter.default.post(name: .showOverlayHUD, object: nil, userInfo: ["action": action])
    }
    
    // MARK: - Spaces Movement Workaround
    private func performSpaceMove(_ window: AXUIElement, frame: CGRect, action: WindowAction) {
        // Calculate the center of the window titlebar (y-offset of 15 is standard)
        let titlebarX = frame.minX + frame.width / 2.0
        let titlebarY = frame.minY + 15
        
        // 1. Post a mouse down event on titlebar
        let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                               mouseCursorPosition: CGPoint(x: titlebarX, y: titlebarY), mouseButton: .left)
        mouseDown?.post(tap: .cghidEventTap)
        
        // Brief delay to ensure system recognizes drag grab
        usleep(50000)
        
        // 2. Simulate standard Spaces switching key triggers (Ctrl + Left/Right Arrow)
        let controlKey: CGKeyCode = 0x3B // Control keycode
        let arrowKey: CGKeyCode = (action == .spacePrev) ? 123 : 124 // Left or Right arrow
        
        let source = CGEventSource(stateID: .combinedSessionState)
        
        let ctrlDown = CGEvent(keyboardEventSource: source, virtualKey: controlKey, keyDown: true)
        let keyPress = CGEvent(keyboardEventSource: source, virtualKey: arrowKey, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: arrowKey, keyDown: false)
        let ctrlUp = CGEvent(keyboardEventSource: source, virtualKey: controlKey, keyDown: false)
        
        // Chain flags
        keyPress?.flags = .maskControl
        keyUp?.flags = .maskControl
        
        // Execute triggers
        ctrlDown?.post(tap: .cghidEventTap)
        usleep(20000)
        keyPress?.post(tap: .cghidEventTap)
        usleep(20000)
        keyUp?.post(tap: .cghidEventTap)
        usleep(20000)
        ctrlUp?.post(tap: .cghidEventTap)
        
        // Wait for OS spaces transition animation
        usleep(250000)
        
        // 3. Post a mouse up event to release
        let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                             mouseCursorPosition: CGPoint(x: titlebarX, y: titlebarY), mouseButton: .left)
        mouseUp?.post(tap: .cghidEventTap)
        
        NotificationCenter.default.post(name: .showOverlayHUD, object: nil, userInfo: ["action": action])
    }
    
    // MARK: - Multi-Monitor Movement Shifts
    private func computeMonitorShift(_ currentFrame: CGRect, action: WindowAction, primaryScreenHeight: CGFloat) -> CGRect {
        let screens = NSScreen.screens
        guard screens.count > 1 else { return currentFrame }
        
        guard let currentScreen = getScreenForWindowFrame(currentFrame, primaryScreenHeight: primaryScreenHeight),
              let currentIndex = screens.firstIndex(of: currentScreen) else {
            return currentFrame
        }
        
        // Resolve adjacent screen index
        let targetIndex: Int
        if action == .nextMonitor {
            targetIndex = (currentIndex + 1) % screens.count
        } else {
            targetIndex = (currentIndex - 1 + screens.count) % screens.count
        }
        
        let targetScreen = screens[targetIndex]
        
        let srcVis = accessibilityRect(for: currentScreen.visibleFrame, primaryScreenHeight: primaryScreenHeight)
        let tgtVis = accessibilityRect(for: targetScreen.visibleFrame, primaryScreenHeight: primaryScreenHeight)
        
        let settings = Settings.shared
        
        if settings.resizeProportionally {
            // Scale and move proportionally
            let relX = (currentFrame.minX - srcVis.minX) / srcVis.width
            let relY = (currentFrame.minY - srcVis.minY) / srcVis.height
            let relW = currentFrame.width / srcVis.width
            let relH = currentFrame.height / srcVis.height
            
            return CGRect(
                x: tgtVis.minX + relX * tgtVis.width,
                y: tgtVis.minY + relY * tgtVis.height,
                width: relW * tgtVis.width,
                height: relH * tgtVis.height
            )
        } else {
            // Keep absolute dimensions (and center if out of bounds)
            let offsetX = currentFrame.minX - srcVis.minX
            let offsetY = currentFrame.minY - srcVis.minY
            
            var newX = tgtVis.minX + offsetX
            var newY = tgtVis.minY + offsetY
            let width = min(currentFrame.width, tgtVis.width)
            let height = min(currentFrame.height, tgtVis.height)
            
            // Boundary clamping
            if newX + width > tgtVis.maxX { newX = tgtVis.maxX - width }
            if newY + height > tgtVis.maxY { newY = tgtVis.maxY - height }
            if newX < tgtVis.minX { newX = tgtVis.minX }
            if newY < tgtVis.minY { newY = tgtVis.minY }
            
            return CGRect(x: newX, y: newY, width: width, height: height)
        }
    }
    
    // MARK: - Core Accessibility API Manipulations
    
    private func getFrontmostWindow() -> AXUIElement? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let pid = frontmostApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        var focusedWindow: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        if result == .success {
            return (focusedWindow as! AXUIElement)
        }
        
        // Fallback: search window list
        var windowList: AnyObject?
        let listResult = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowList)
        if listResult == .success, let windows = windowList as? [AXUIElement] {
            return windows.first
        }
        
        return nil
    }
    
    private func getWindowFrame(_ window: AXUIElement) -> CGRect? {
        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        
        let posResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
        let sizeResult = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
        
        guard posResult == .success, sizeResult == .success else { return nil }
        
        var position = CGPoint.zero
        var size = CGSize.zero
        
        AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        
        return CGRect(origin: position, size: size)
    }
    
    private func setWindowFrame(_ window: AXUIElement, frame: CGRect) {
        let targetFrame = frame
        let settings = Settings.shared
        
        // 1. Set Size
        var size = targetFrame.size
        if let sizeRef = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeRef)
        }
        
        // 2. Set Position
        var position = targetFrame.origin
        if let positionRef = AXValueCreate(.cgPoint, &position) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionRef)
        }
        
        // 3. Keep in Bounds & Center Unresizable verification
        // Check what size was actually set (some windows have constraints)
        guard let actualFrame = getWindowFrame(window) else { return }
        
        var needsReadjustment = false
        var finalX = targetFrame.minX
        var finalY = targetFrame.minY
        
        if settings.centerUnresizable {
            // If the window could not shrink to target width or height, center it in target area
            if actualFrame.width > targetFrame.width + 2 {
                finalX = targetFrame.minX + (targetFrame.width - actualFrame.width) / 2.0
                needsReadjustment = true
            }
            if actualFrame.height > targetFrame.height + 2 {
                finalY = targetFrame.minY + (targetFrame.height - actualFrame.height) / 2.0
                needsReadjustment = true
            }
        }
        
        if settings.keepInBounds {
            // Keep window within the active display visible space
            let primaryHeight = NSScreen.screens[0].frame.height
            if let screen = getScreenForWindowFrame(actualFrame, primaryScreenHeight: primaryHeight) {
                let visFrame = accessibilityRect(for: screen.visibleFrame, primaryScreenHeight: primaryHeight)
                
                if finalX + actualFrame.width > visFrame.maxX {
                    finalX = visFrame.maxX - actualFrame.width
                    needsReadjustment = true
                }
                if finalY + actualFrame.height > visFrame.maxY {
                    finalY = visFrame.maxY - actualFrame.height
                    needsReadjustment = true
                }
                if finalX < visFrame.minX {
                    finalX = visFrame.minX
                    needsReadjustment = true
                }
                if finalY < visFrame.minY {
                    finalY = visFrame.minY
                    needsReadjustment = true
                }
            }
        }
        
        if needsReadjustment {
            var readjustedPos = CGPoint(x: finalX, y: finalY)
            if let posRef = AXValueCreate(.cgPoint, &readjustedPos) {
                AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posRef)
            }
        }
    }
    
    // MARK: - Utilities and Coord translations
    
    private func getWindowIdentifier(_ window: AXUIElement) -> String {
        // Use CFHash to uniquely reference AXUIElement pointers during runtime
        let hash = CFHash(window)
        return String(hash)
    }
    
    func getScreenForWindowFrame(_ windowFrame: CGRect, primaryScreenHeight: CGFloat) -> NSScreen? {
        let cocoaFrame = NSRect(
            x: windowFrame.origin.x,
            y: primaryScreenHeight - (windowFrame.origin.y + windowFrame.size.height),
            width: windowFrame.size.width,
            height: windowFrame.size.height
        )
        
        var bestScreen = NSScreen.main
        var maxArea: CGFloat = 0
        
        for screen in NSScreen.screens {
            let intersection = NSIntersectionRect(cocoaFrame, screen.frame)
            let area = intersection.width * intersection.height
            if area > maxArea {
                maxArea = area
                bestScreen = screen
            }
        }
        
        return bestScreen
    }
    
    func accessibilityRect(for cocoaRect: NSRect, primaryScreenHeight: CGFloat) -> CGRect {
        return CGRect(
            x: cocoaRect.origin.x,
            y: primaryScreenHeight - (cocoaRect.origin.y + cocoaRect.size.height),
            width: cocoaRect.size.width,
            height: cocoaRect.size.height
        )
    }
}

// Notification names
extension Notification.Name {
    static let showOverlayHUD = Notification.Name("FreeSizeUpShowOverlayHUD")
    static let accessibilityDenied = Notification.Name("FreeSizeUpAccessibilityDenied")
}
