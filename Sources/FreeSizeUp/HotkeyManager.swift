import Carbon
import Cocoa

@MainActor
class HotkeyManager {
    static let shared = HotkeyManager()
    
    // Map to keep track of active registered hotkeys: Action -> EventHotKeyRef
    private var registeredKeys: [WindowAction: EventHotKeyRef] = [:]
    
    // Action to ID mapping for Carbon EventHotKeyID
    private let actionToId: [WindowAction: UInt32] = [
        .left: 1, .right: 2, .up: 3, .down: 4,
        .upperLeft: 5, .upperRight: 6, .lowerLeft: 7, .lowerRight: 8,
        .fullScreen: 9, .center: 10, .snapBack: 11,
        .prevMonitor: 12, .nextMonitor: 13,
        .spacePrev: 14, .spaceNext: 15
    ]
    
    private var idToAction: [UInt32: WindowAction] = [:]
    private var eventHandler: EventHandlerRef?
    
    // Callback block to execute when a hotkey triggers
    var onHotkeyTriggered: ((WindowAction) -> Void)?
    
    private init() {
        // Build reverse map
        for (action, id) in actionToId {
            idToAction[id] = action
        }
        
        setupCarbonEventHandler()
        
        // Listen to shortcuts updates in Settings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateHotkeys),
            name: .shortcutsChanged,
            object: nil
        )
    }

    
    // Set up Carbon Event Handler for kEventHotKeyPressed
    private func setupCarbonEventHandler() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        // C-style Callback function
        let handlerUPP: EventHandlerUPP = { (nextHandler, event, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if status == noErr {
                let id = hotKeyID.id
                // Post event to hotkey manager instance
                DispatchQueue.main.async {
                    HotkeyManager.shared.handleHotkeyTriggered(id: id)
                }
            }
            
            return noErr
        }
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            handlerUPP,
            1,
            &eventSpec,
            nil,
            &eventHandler
        )
        
        if status != noErr {
            print("FreeSizeUp: Failed to install Carbon event handler. Status: \(status)")
        }
    }
    
    // Main trigger dispatcher
    private func handleHotkeyTriggered(id: UInt32) {
        guard let action = idToAction[id] else { return }
        
        // Only execute if shortcuts are globally enabled in settings
        guard Settings.shared.enableShortcuts else { return }
        
        onHotkeyTriggered?(action)
    }
    
    // Public registration update
    @objc func updateHotkeys() {
        unregisterAll()
        
        guard Settings.shared.enableShortcuts else {
            print("FreeSizeUp: Global shortcuts disabled in settings.")
            return
        }
        
        let settings = Settings.shared
        for (action, shortcutOpt) in settings.shortcuts {
            guard let shortcut = shortcutOpt else { continue }
            guard let actionId = actionToId[action] else { continue }
            
            register(action: action, id: actionId, keyCode: shortcut.keyCode, modifiers: shortcut.modifierFlags)
        }
    }
    
    // Register a specific shortcut in Carbon
    private func register(action: WindowAction, id: UInt32, keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        let carbonFlags = carbonModifiers(from: modifiers)
        
        // Carbon ID signature and identifier
        // "FSU!" signature (FreeSizeUp!)
        let signature = OSType(1179604257) // UInt32 bitpattern of "FSU!"
        let hotKeyID = EventHotKeyID(signature: signature, id: id)
        
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            carbonFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr, let ref = hotKeyRef {
            registeredKeys[action] = ref
        } else {
            print("FreeSizeUp: Failed to register hotkey \(action) (\(keyCode)). Status: \(status)")
        }
    }
    
    // Unregister all hotkeys
    func unregisterAll() {
        for (action, ref) in registeredKeys {
            let status = UnregisterEventHotKey(ref)
            if status != noErr {
                print("FreeSizeUp: Failed to unregister hotkey for \(action). Status: \(status)")
            }
        }
        registeredKeys.removeAll()
    }
    
    // Helper to map Cocoa modifier flags to Carbon modifiers
    private func carbonModifiers(from cocoaFlags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonFlags: UInt32 = 0
        if cocoaFlags.contains(.command) { carbonFlags |= UInt32(cmdKey) }
        if cocoaFlags.contains(.option) { carbonFlags |= UInt32(optionKey) }
        if cocoaFlags.contains(.shift) { carbonFlags |= UInt32(shiftKey) }
        if cocoaFlags.contains(.control) { carbonFlags |= UInt32(controlKey) }
        return carbonFlags
    }
}
