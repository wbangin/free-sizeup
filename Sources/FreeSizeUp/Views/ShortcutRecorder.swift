import SwiftUI
import Carbon

struct ShortcutRecorder: View {
    @Binding var shortcut: KeyShortcut?
    @State private var isRecording = false
    @State private var localMonitor: Any?
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }) {
            HStack(spacing: 8) {
                if isRecording {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                            .opacity(isRecording ? 1.0 : 0.2)
                            .scaleEffect(isRecording ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isRecording)
                        
                        Text("Press shortcuts...")
                            .foregroundColor(.blue)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                    }
                } else if let shortcut = shortcut {
                    Text(shortcut.displayString)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                } else {
                    Text("Record Shortcut")
                        .foregroundColor(.secondary)
                        .font(.system(.body, design: .rounded))
                }
                
                // Clear button if shortcut is present and not recording
                if shortcut != nil && !isRecording {
                    Button(action: {
                        shortcut = nil
                        NotificationCenter.default.post(name: .shortcutsChanged, object: nil)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary.opacity(0.7))
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(minWidth: 140, minHeight: 30)
            .background(isRecording ? Color.blue.opacity(0.08) : (isHovering ? Color.primary.opacity(0.07) : Color.primary.opacity(0.035)))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isRecording ? Color.blue : Color.primary.opacity(0.12), lineWidth: 1.2)
            )
            .animation(.easeInOut(duration: 0.15), value: isRecording)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        // Listen to cancellation notifications from other recorders starting up
        .onReceive(NotificationCenter.default.publisher(for: .cancelActiveShortcutRecording)) { _ in
            if isRecording {
                stopRecording()
            }
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func startRecording() {
        // Cancel all other active shortcut recording views
        NotificationCenter.default.post(name: .cancelActiveShortcutRecording, object: nil)
        
        isRecording = true
        
        // Monitor key events locally in our preference window
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if event.type == .keyDown {
                let keyCode = event.keyCode
                
                // Escape key (53) -> cancels recording
                if keyCode == 53 {
                    self.stopRecording()
                    return nil
                }
                
                // Capture modifiers
                let flags = event.modifierFlags.intersection([.command, .option, .shift, .control])
                let hasModifiers = !flags.isEmpty
                
                if hasModifiers {
                    let modifiersRaw = Int(flags.rawValue)
                    
                    // Prevent single key mappings like only Command or Control
                    let singleModifier = flags == .command || flags == .option || flags == .shift || flags == .control
                    // Ignore mapping if it's just Command + Space (system shortcut)
                    if singleModifier && keyCode == 49 { return event }
                    
                    self.shortcut = KeyShortcut(keyCode: keyCode, modifiers: modifiersRaw)
                    
                    // Post shortcuts change notification to update active hotkeys
                    NotificationCenter.default.post(name: .shortcutsChanged, object: nil)
                    self.stopRecording()
                }
                
                return nil // consume keys
            }
            
            return event
        }
    }
    
    func stopRecording() {
        if isRecording {
            isRecording = false
            if let monitor = localMonitor {
                NSEvent.removeMonitor(monitor)
                localMonitor = nil
            }
        }
    }
}

// Global Notification Name for shortcut recorder isolation
extension Notification.Name {
    static let cancelActiveShortcutRecording = Notification.Name("FreeSizeUpCancelActiveShortcutRecording")
}
