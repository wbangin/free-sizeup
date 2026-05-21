import Cocoa
import SwiftUI
import Combine
import Carbon

// Supported Color Themes
enum AppTheme: String, Codable, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// Struct to represent a Keyboard Shortcut
struct KeyShortcut: Codable, Equatable, Hashable {
    var keyCode: UInt16
    var modifiers: Int // Store Cocoa NSEvent.ModifierFlags raw value
    
    var modifierFlags: NSEvent.ModifierFlags {
        return NSEvent.ModifierFlags(rawValue: UInt(modifiers))
    }
    
    // Display representation (e.g. ⌃⌥⌘←)
    var displayString: String {
        var str = ""
        let flags = modifierFlags
        if flags.contains(.control) { str += "⌃" }
        if flags.contains(.option) { str += "⌥" }
        if flags.contains(.shift) { str += "⇧" }
        if flags.contains(.command) { str += "⌘" }
        
        str += Self.keyName(for: keyCode)
        return str
    }
    
    // Helper to get string name for standard key codes
    static func keyName(for keyCode: UInt16) -> String {
        switch keyCode {
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        case 49: return "Space"
        case 36: return "↩"
        case 53: return "⎋"
        case 44: return "/"
        case 8: return "C"
        case 46: return "M"
        default:
            // Get character representation using Carbon APIs
            if let string = character(for: keyCode) {
                return string.uppercased()
            }
            return "Key \(keyCode)"
        }
    }
    
    private static func character(for keyCode: UInt16) -> String? {
        let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource().takeRetainedValue()
        let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        guard let data = layoutData else { return nil }
        
        let rawData = Unmanaged<CFData>.fromOpaque(data).takeUnretainedValue() as Data
        return rawData.withUnsafeBytes { pointer -> String? in
            guard let keyLayout = pointer.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else { return nil }
            
            var deadKeys: UInt32 = 0
            let maxStringLength = 4
            var unicodeString = [UniChar](repeating: 0, count: maxStringLength)
            var actualStringLength = 0
            
            let result = UCKeyTranslate(
                keyLayout,
                keyCode,
                UInt16(kUCKeyActionDown),
                0,
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysMask),
                &deadKeys,
                maxStringLength,
                &actualStringLength,
                &unicodeString
            )
            
            if result == noErr && actualStringLength > 0 {
                return String(utf16CodeUnits: unicodeString, count: actualStringLength)
            }
            return nil
        }
    }
}

// Action Types in FreeSizeUp
enum WindowAction: String, CaseIterable, Codable {
    case left = "Left"
    case right = "Right"
    case up = "Up"
    case down = "Down"
    
    case upperLeft = "Upper Left"
    case upperRight = "Upper Right"
    case lowerLeft = "Lower Left"
    case lowerRight = "Lower Right"
    
    case fullScreen = "Full Screen"
    case center = "Center"
    case snapBack = "SnapBack"
    
    case prevMonitor = "Prev Monitor"
    case nextMonitor = "Next Monitor"
    
    case spacePrev = "Space Prev"
    case spaceNext = "Space Next"
    
    var iconName: String {
        switch self {
        case .left: return "square.split.2x1.left"
        case .right: return "square.split.2x1.right"
        case .up: return "square.split.1x2.top"
        case .down: return "square.split.1x2.bottom"
        case .upperLeft: return "arrow.up.left.square.fill"
        case .upperRight: return "arrow.up.right.square.fill"
        case .lowerLeft: return "arrow.down.left.square.fill"
        case .lowerRight: return "arrow.down.right.square.fill"
        case .fullScreen: return "arrow.up.left.and.arrow.down.right.square.fill"
        case .center: return "square.inset.filled"
        case .snapBack: return "arrow.uturn.backward.square.fill"
        case .prevMonitor: return "arrow.left.square.fill"
        case .nextMonitor: return "arrow.right.square.fill"
        case .spacePrev: return "macwindow.badge.minus"
        case .spaceNext: return "macwindow.badge.plus"
        }
    }
}

// Main Settings State (ObservableObject to sync seamlessly with SwiftUI views)
@MainActor
class Settings: ObservableObject {
    static let shared = Settings()
    
    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // Appearance & General Settings
    @Published var theme: AppTheme = .system
    @Published var startAtLogin: Bool = false
    @Published var showPreferencesOnLaunch: Bool = true
    @Published var showInMenuBar: Bool = true
    @Published var showVisualActionOverlay: Bool = true
    @Published var enableShortcuts: Bool = true
    
    // Margins Settings (pixels)
    @Published var marginTop: Int = 0
    @Published var marginBottom: Int = 0
    @Published var marginLeft: Int = 0
    @Published var marginRight: Int = 0
    
    // Partitions Settings (percentages: 0.1 to 0.9)
    @Published var partitionLeftRight: Double = 0.5
    @Published var partitionTopBottom: Double = 0.5
    
    // Advanced Behavior Settings
    @Published var centerUnresizable: Bool = true
    @Published var keepInBounds: Bool = true
    @Published var resizeProportionally: Bool = true
    
    // Custom Shortcuts dictionary
    @Published var shortcuts: [WindowAction: KeyShortcut?] = [:]
    
    private init() {
        loadSettings()
        
        // Setup automatic saves whenever fields change
        let anyChange = Publishers.MergeMany(
            $theme.map { _ in () }.eraseToAnyPublisher(),
            $startAtLogin.map { _ in () }.eraseToAnyPublisher(),
            $showPreferencesOnLaunch.map { _ in () }.eraseToAnyPublisher(),
            $showInMenuBar.map { _ in () }.eraseToAnyPublisher(),
            $showVisualActionOverlay.map { _ in () }.eraseToAnyPublisher(),
            $enableShortcuts.map { _ in () }.eraseToAnyPublisher(),
            Publishers.MergeMany(
                $marginTop.map { _ in () }.eraseToAnyPublisher(),
                $marginBottom.map { _ in () }.eraseToAnyPublisher(),
                $marginLeft.map { _ in () }.eraseToAnyPublisher(),
                $marginRight.map { _ in () }.eraseToAnyPublisher(),
                $partitionLeftRight.map { _ in () }.eraseToAnyPublisher(),
                $partitionTopBottom.map { _ in () }.eraseToAnyPublisher()
            ).eraseToAnyPublisher(),
            Publishers.MergeMany(
                $centerUnresizable.map { _ in () }.eraseToAnyPublisher(),
                $keepInBounds.map { _ in () }.eraseToAnyPublisher(),
                $resizeProportionally.map { _ in () }.eraseToAnyPublisher(),
                $shortcuts.map { _ in () }.eraseToAnyPublisher()
            ).eraseToAnyPublisher()
        )
        
        anyChange
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.saveSettings()
            }
            .store(in: &cancellables)
    }
    
    // Restore default settings
    func restoreDefaults() {
        theme = .system
        startAtLogin = false
        showPreferencesOnLaunch = true
        showInMenuBar = true
        showVisualActionOverlay = true
        enableShortcuts = true
        
        marginTop = 0
        marginBottom = 0
        marginLeft = 0
        marginRight = 0
        
        partitionLeftRight = 0.5
        partitionTopBottom = 0.5
        
        centerUnresizable = true
        keepInBounds = true
        resizeProportionally = true
        
        loadDefaultShortcuts()
        
        // Post a notification that shortcuts changed so the hotkey manager registers new ones
        NotificationCenter.default.post(name: .shortcutsChanged, object: nil)
    }
    
    private func loadDefaultShortcuts() {
        let ctrlOptCmd = Int(NSEvent.ModifierFlags([.control, .option, .command]).rawValue)
        let ctrlOptShift = Int(NSEvent.ModifierFlags([.control, .option, .shift]).rawValue)
        let ctrlOpt = Int(NSEvent.ModifierFlags([.control, .option]).rawValue)
        let ctrlCmd = Int(NSEvent.ModifierFlags([.control, .command]).rawValue)
        
        shortcuts = [
            // Halves: Control + Option + Command + Arrow
            .left: KeyShortcut(keyCode: 123, modifiers: ctrlOptCmd),
            .right: KeyShortcut(keyCode: 124, modifiers: ctrlOptCmd),
            .up: KeyShortcut(keyCode: 126, modifiers: ctrlOptCmd),
            .down: KeyShortcut(keyCode: 125, modifiers: ctrlOptCmd),
            
            // Corners: Control + Option + Shift + Arrow
            .upperLeft: KeyShortcut(keyCode: 123, modifiers: ctrlOptShift),
            .upperRight: KeyShortcut(keyCode: 126, modifiers: ctrlOptShift),
            .lowerLeft: KeyShortcut(keyCode: 125, modifiers: ctrlOptShift),
            .lowerRight: KeyShortcut(keyCode: 124, modifiers: ctrlOptShift),
            
            // Fullscreen & Center: Control + Option + Command + M/C
            .fullScreen: KeyShortcut(keyCode: 46, modifiers: ctrlOptCmd),
            .center: KeyShortcut(keyCode: 8, modifiers: ctrlOptCmd),
            
            // SnapBack: Control + Option + Command + /
            .snapBack: KeyShortcut(keyCode: 44, modifiers: ctrlOptCmd),
            
            // Multi-monitor: Control + Option + Arrow
            .prevMonitor: KeyShortcut(keyCode: 123, modifiers: ctrlOpt),
            .nextMonitor: KeyShortcut(keyCode: 124, modifiers: ctrlOpt),
            
            // Spaces: Control + Command + Arrow
            .spacePrev: KeyShortcut(keyCode: 123, modifiers: ctrlCmd),
            .spaceNext: KeyShortcut(keyCode: 124, modifiers: ctrlCmd)
        ]
    }
    
    private func loadSettings() {
        theme = AppTheme(rawValue: defaults.string(forKey: "theme") ?? "System") ?? .system
        startAtLogin = defaults.object(forKey: "startAtLogin") == nil ? false : defaults.bool(forKey: "startAtLogin")
        showPreferencesOnLaunch = defaults.object(forKey: "showPreferencesOnLaunch") == nil ? true : defaults.bool(forKey: "showPreferencesOnLaunch")
        showInMenuBar = defaults.object(forKey: "showInMenuBar") == nil ? true : defaults.bool(forKey: "showInMenuBar")
        showVisualActionOverlay = defaults.object(forKey: "showVisualActionOverlay") == nil ? true : defaults.bool(forKey: "showVisualActionOverlay")
        enableShortcuts = defaults.object(forKey: "enableShortcuts") == nil ? true : defaults.bool(forKey: "enableShortcuts")
        
        marginTop = defaults.integer(forKey: "marginTop")
        marginBottom = defaults.integer(forKey: "marginBottom")
        marginLeft = defaults.integer(forKey: "marginLeft")
        marginRight = defaults.integer(forKey: "marginRight")
        
        partitionLeftRight = defaults.object(forKey: "partitionLeftRight") == nil ? 0.5 : defaults.double(forKey: "partitionLeftRight")
        partitionTopBottom = defaults.object(forKey: "partitionTopBottom") == nil ? 0.5 : defaults.double(forKey: "partitionTopBottom")
        
        centerUnresizable = defaults.object(forKey: "centerUnresizable") == nil ? true : defaults.bool(forKey: "centerUnresizable")
        keepInBounds = defaults.object(forKey: "keepInBounds") == nil ? true : defaults.bool(forKey: "keepInBounds")
        resizeProportionally = defaults.object(forKey: "resizeProportionally") == nil ? true : defaults.bool(forKey: "resizeProportionally")
        
        if let savedShortcutsData = defaults.data(forKey: "shortcuts") {
            do {
                shortcuts = try JSONDecoder().decode([WindowAction: KeyShortcut?].self, from: savedShortcutsData)
            } catch {
                loadDefaultShortcuts()
            }
        } else {
            loadDefaultShortcuts()
        }
    }
    
    func saveSettings() {
        defaults.set(theme.rawValue, forKey: "theme")
        defaults.set(startAtLogin, forKey: "startAtLogin")
        defaults.set(showPreferencesOnLaunch, forKey: "showPreferencesOnLaunch")
        defaults.set(showInMenuBar, forKey: "showInMenuBar")
        defaults.set(showVisualActionOverlay, forKey: "showVisualActionOverlay")
        defaults.set(enableShortcuts, forKey: "enableShortcuts")
        
        defaults.set(marginTop, forKey: "marginTop")
        defaults.set(marginBottom, forKey: "marginBottom")
        defaults.set(marginLeft, forKey: "marginLeft")
        defaults.set(marginRight, forKey: "marginRight")
        
        defaults.set(partitionLeftRight, forKey: "partitionLeftRight")
        defaults.set(partitionTopBottom, forKey: "partitionTopBottom")
        
        defaults.set(centerUnresizable, forKey: "centerUnresizable")
        defaults.set(keepInBounds, forKey: "keepInBounds")
        defaults.set(resizeProportionally, forKey: "resizeProportionally")
        
        do {
            let data = try JSONEncoder().encode(shortcuts)
            defaults.set(data, forKey: "shortcuts")
        } catch {
            print("Failed to save shortcuts: \(error)")
        }
        
        // Sync layout theme immediately across the whole application
        DispatchQueue.main.async {
            self.applyTheme()
        }
    }
    
    func applyTheme() {
        switch theme {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .system:
            NSApp.appearance = nil // Reverts to system appearance
        }
    }
}

// Notification names
extension Notification.Name {
    static let shortcutsChanged = Notification.Name("FreeSizeUpShortcutsChanged")
}
