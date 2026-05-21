import Cocoa
import SwiftUI

@MainActor
class OverlayManager {
    static let shared = OverlayManager()
    
    private var hudWindow: NSPanel?
    private var dismissTimer: Timer?
    
    private init() {
        // Listen to HUD requests from the WindowManager
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showHUDNotification(_:)),
            name: .showOverlayHUD,
            object: nil
        )
    }
    
    @objc private func showHUDNotification(_ notification: Notification) {
        guard Settings.shared.showVisualActionOverlay else { return }
        
        guard let userInfo = notification.userInfo,
              let action = userInfo["action"] as? WindowAction else {
            return
        }
        
        DispatchQueue.main.async {
            self.showHUD(for: action)
        }
    }
    
    func showHUD(for action: WindowAction) {
        // Cancel existing dismiss timer & close old window
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        if let window = hudWindow {
            window.close()
            hudWindow = nil
        }
        
        // 1. Identify current active screen where the window resides
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.frame
        
        // 2. Build standard borderless translucent overlay panel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 140, height: 120),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        
        // 3. Attach SwiftUI content view with support for system color schemes
        let hudView = HUDContentView(action: action)
            .environment(\.colorScheme, Settings.shared.theme.colorScheme ?? (NSApp.effectiveAppearance.name == .darkAqua ? .dark : .light))
        
        let hostingView = NSHostingView(rootView: hudView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 140, height: 120)
        panel.contentView = hostingView
        
        // Center on screen
        let x = screenFrame.minX + (screenFrame.width - 140) / 2.0
        let y = screenFrame.minY + (screenFrame.height - 120) / 2.0
        panel.setFrameOrigin(NSPoint(x: x, y: y))
        
        // 4. Initial alpha to 0 for fade in
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        
        hudWindow = panel
        
        // Animate fade-in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 1.0
        } completionHandler: {
            Task { @MainActor in
                // Keep HUD on screen for 0.6 seconds, then fade out
                self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        self?.dismissHUD()
                    }
                }
            }
        }
    }
    
    private func dismissHUD() {
        guard let panel = hudWindow else { return }
        
        // Animate fade-out
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 0.0
        } completionHandler: {
            Task { @MainActor in
                panel.close()
                if self.hudWindow === panel {
                    self.hudWindow = nil
                }
            }
        }
    }
}

// MARK: - HUD Content Views

struct HUDContentView: View {
    let action: WindowAction
    
    var body: some View {
        VStack(spacing: 10) {
            // Screen split schematic mock
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 70, height: 44)
                    .background(Color.primary.opacity(0.02))
                
                // Overlay highlights representing action
                schematicHighlight
            }
            .frame(width: 70, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            
            // Layout Action Label
            Text(action.rawValue)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 130, height: 110)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var schematicHighlight: some View {
        let gradient = LinearGradient(
            colors: [Color.blue.opacity(0.75), Color.purple.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        switch action {
        case .left:
            HStack(spacing: 0) {
                gradient.frame(width: 35)
                Spacer(minLength: 0)
            }
            .frame(width: 70, height: 44)
            
        case .right:
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                gradient.frame(width: 35)
            }
            .frame(width: 70, height: 44)
            
        case .up:
            VStack(spacing: 0) {
                gradient.frame(height: 22)
                Spacer(minLength: 0)
            }
            .frame(width: 70, height: 44)
            
        case .down:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                gradient.frame(height: 22)
            }
            .frame(width: 70, height: 44)
            
        case .upperLeft:
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    gradient.frame(width: 35, height: 22)
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
            .frame(width: 70, height: 44)
            
        case .upperRight:
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    gradient.frame(width: 35, height: 22)
                }
                Spacer(minLength: 0)
            }
            .frame(width: 70, height: 44)
            
        case .lowerLeft:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    gradient.frame(width: 35, height: 22)
                    Spacer(minLength: 0)
                }
            }
            .frame(width: 70, height: 44)
            
        case .lowerRight:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    gradient.frame(width: 35, height: 22)
                }
            }
            .frame(width: 70, height: 44)
            
        case .fullScreen:
            gradient
                .frame(width: 70, height: 44)
            
        case .center:
            gradient
                .frame(width: 50, height: 32)
                .cornerRadius(3)
            
        case .snapBack:
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.blue)
            
        case .prevMonitor:
            Image(systemName: "arrow.left.square.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.blue)
            
        case .nextMonitor:
            Image(systemName: "arrow.right.square.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.blue)
            
        case .spacePrev:
            Image(systemName: "arrow.left.to.line")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.purple)
            
        case .spaceNext:
            Image(systemName: "arrow.right.to.line")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.purple)
        }
    }
}
