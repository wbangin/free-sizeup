import SwiftUI

// Category tabs for Sidebar
enum PrefTab: String, CaseIterable {
    case general = "General"
    case shortcuts = "Shortcuts"
    case margins = "Margins"
    case partitions = "Partitions"
    case advanced = "Advanced"
    
    var iconName: String {
        switch self {
        case .general: return "gearshape.fill"
        case .shortcuts: return "keyboard.fill"
        case .margins: return "arrow.up.and.down.and.arrow.left.and.right"
        case .partitions: return "square.split.2x2.fill"
        case .advanced: return "slider.horizontal.3"
        }
    }
    
    var color: Color {
        switch self {
        case .general: return .blue
        case .shortcuts: return .green
        case .margins: return .orange
        case .partitions: return .purple
        case .advanced: return .gray
        }
    }
}

struct PreferencesView: View {
    @ObservedObject var settings = Settings.shared
    @State private var activeTab: PrefTab = .general
    
    // Accessibility Permission Status
    @State private var hasAccessibilityPermission = WindowManager.shared.checkAccessibilityPermissions(prompt: false)
    
    var body: some View {
        HStack(spacing: 0) {
            // 1. Sidebar Navigation
            VStack(alignment: .leading, spacing: 6) {
                Text("FreeSizeUp")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                
                ForEach(PrefTab.allCases, id: \.self) { tab in
                    Button(action: {
                        activeTab = tab
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(tab.color.opacity(0.12))
                                    .frame(width: 24, height: 24)
                                
                                Image(systemName: tab.iconName)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(tab.color)
                            }
                            
                            Text(tab.rawValue)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(activeTab == tab ? .semibold : .regular)
                                .foregroundColor(activeTab == tab ? .primary : .secondary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(activeTab == tab ? Color.primary.opacity(0.06) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Sidebar Footer with version info
                Text("v1.0.0 (Beta)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
            .frame(width: 180)
            .background(Color.primary.opacity(0.02))
            .overlay(
                Divider().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            )
            
            // 2. Main content Panel
            VStack(spacing: 0) {
                // Header Alert for missing Accessibility Permissions
                if !hasAccessibilityPermission {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accessibility Permission Required")
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("FreeSizeUp needs access to control and resize windows of other apps.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Grant Access") {
                            _ = WindowManager.shared.checkAccessibilityPermissions(prompt: true)
                            // Re-verify after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                hasAccessibilityPermission = WindowManager.shared.checkAccessibilityPermissions(prompt: false)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.08))
                    .overlay(Divider(), alignment: .bottom)
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        switch activeTab {
                        case .general:
                            generalSection
                        case .shortcuts:
                            shortcutsSection
                        case .margins:
                            marginsSection
                        case .partitions:
                            partitionsSection
                        case .advanced:
                            advancedSection
                        }
                    }
                    .padding(28)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 720, height: 500)
        .onReceive(Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()) { _ in
            hasAccessibilityPermission = WindowManager.shared.checkAccessibilityPermissions(prompt: false)
        }
    }
    
    // MARK: - General Settings Tab
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General Settings")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 14) {
                Text("Appearance Theme")
                    .fontWeight(.semibold)
                
                // Premium visual card selectors for Theme
                HStack(spacing: 16) {
                    ForEach(AppTheme.allCases, id: \.self) { item in
                        Button(action: {
                            settings.theme = item
                        }) {
                            VStack(spacing: 8) {
                                // Theme Mini Mock
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(settings.theme == item ? Color.blue : Color.primary.opacity(0.15), lineWidth: settings.theme == item ? 2.2 : 1.2)
                                        .frame(width: 80, height: 52)
                                        .background(
                                            themeMockBackground(for: item)
                                                .cornerRadius(8)
                                        )
                                    
                                    if settings.theme == item {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .background(Circle().fill(Color.white))
                                            .offset(x: 32, y: -20)
                                    }
                                }
                                
                                Text(item.rawValue)
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.medium)
                                    .foregroundColor(settings.theme == item ? .blue : .primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.bottom, 8)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Application Control")
                    .fontWeight(.semibold)
                
                Toggle("Start FreeSizeUp Automatically at Login", isOn: $settings.startAtLogin)
                    .toggleStyle(.checkbox)
                
                Toggle("Show Preferences on Launch", isOn: $settings.showPreferencesOnLaunch)
                    .toggleStyle(.checkbox)
                
                Toggle("Show FreeSizeUp in Menu Bar", isOn: $settings.showInMenuBar)
                    .toggleStyle(.checkbox)
                
                Toggle("Show Visual Action Overlay (HUD on Trigger)", isOn: $settings.showVisualActionOverlay)
                    .toggleStyle(.checkbox)
                
                Toggle("Enable Global Window Shortcuts", isOn: $settings.enableShortcuts)
                    .toggleStyle(.checkbox)
            }
        }
    }
    
    @ViewBuilder
    private func themeMockBackground(for item: AppTheme) -> some View {
        switch item {
        case .light:
            Color.white
                .overlay(
                    VStack {
                        Color.gray.opacity(0.12).frame(height: 10)
                        Spacer()
                        HStack {
                            Color.blue.opacity(0.15).frame(width: 32, height: 26).cornerRadius(3)
                            Spacer()
                        }.padding(4)
                    }
                )
        case .dark:
            Color(red: 0.15, green: 0.15, blue: 0.17)
                .overlay(
                    VStack {
                        Color.white.opacity(0.1).frame(height: 10)
                        Spacer()
                        HStack {
                            Color.blue.opacity(0.3).frame(width: 32, height: 26).cornerRadius(3)
                            Spacer()
                        }.padding(4)
                    }
                )
        case .system:
            HStack(spacing: 0) {
                Color.white
                Color(red: 0.15, green: 0.15, blue: 0.17)
            }
            .overlay(
                VStack {
                    Color.gray.opacity(0.12).frame(height: 10)
                    Spacer()
                    HStack {
                        Color.blue.opacity(0.2).frame(width: 32, height: 26).cornerRadius(3)
                        Spacer()
                    }.padding(4)
                }
            )
        }
    }
    
    // MARK: - Shortcuts Settings Tab
    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Shortcut Configurations")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Restore Defaults") {
                    settings.restoreDefaults()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Text("Click on any shortcut field below and press your desired keyboard combination to record it.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 6)
            
            Group {
                shortcutCategoryHeader("Split Screen Actions", icon: "square.split.2x1.fill")
                VStack(spacing: 10) {
                    shortcutRow("Left Half", action: .left)
                    shortcutRow("Right Half", action: .right)
                    shortcutRow("Top Half", action: .up)
                    shortcutRow("Bottom Half", action: .down)
                }
                .padding(.bottom, 12)
                
                shortcutCategoryHeader("Quarter Screen (Quadrant) Actions", icon: "square.split.2x2.fill")
                VStack(spacing: 10) {
                    shortcutRow("Upper Left Corner", action: .upperLeft)
                    shortcutRow("Upper Right Corner", action: .upperRight)
                    shortcutRow("Lower Left Corner", action: .lowerLeft)
                    shortcutRow("Lower Right Corner", action: .lowerRight)
                }
                .padding(.bottom, 12)
                
                shortcutCategoryHeader("Display & Spaces Actions", icon: "display.2")
                VStack(spacing: 10) {
                    shortcutRow("Previous Monitor", action: .prevMonitor)
                    shortcutRow("Next Monitor", action: .nextMonitor)
                    shortcutRow("Previous Space", action: .spacePrev)
                    shortcutRow("Next Space", action: .spaceNext)
                }
                .padding(.bottom, 12)
                
                shortcutCategoryHeader("Other Actions & SnapBack", icon: "arrow.uturn.backward.square.fill")
                VStack(spacing: 10) {
                    shortcutRow("Full Screen", action: .fullScreen)
                    shortcutRow("Center", action: .center)
                    shortcutRow("SnapBack (Undo)", action: .snapBack)
                }
            }
        }
    }
    
    private func shortcutCategoryHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.system(size: 13, weight: .bold))
            Text(title)
                .font(.system(.body, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func shortcutRow(_ label: String, action: WindowAction) -> some View {
        HStack(spacing: 12) {
            // Unified mini layout schematic icon
            MiniSchematicIcon(action: action)
            
            Text(label)
                .font(.system(.body, design: .rounded))
            
            Spacer()
            
            // Render Custom Shortcut Recorder binding
            ShortcutRecorder(shortcut: Binding(
                get: { settings.shortcuts[action] ?? nil },
                set: { settings.shortcuts[action] = $0 }
            ))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.015))
        .cornerRadius(6)
    }
    
    // MARK: - Margins Settings Tab
    private var marginsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Screen Edge Margins")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
            
            Text("Define margin offsets (in pixels) around screen borders. Resized windows will not overlap these margins.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 40) {
                // Stepper Settings Form
                VStack(alignment: .leading, spacing: 14) {
                    marginStepper("Top Margin", value: $settings.marginTop)
                    marginStepper("Bottom Margin", value: $settings.marginBottom)
                    marginStepper("Left Margin", value: $settings.marginLeft)
                    marginStepper("Right Margin", value: $settings.marginRight)
                }
                .frame(width: 240)
                
                Spacer()
                
                // Real-time Visual Margin Preview Shading mockup!
                VStack(spacing: 8) {
                    Text("Interactive Preview")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        // Main Mock Screen
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.18), lineWidth: 2)
                            .frame(width: 200, height: 120)
                            .background(Color.primary.opacity(0.01))
                        
                        // Margin Shaded Overlay Area
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.blue.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                            )
                            // Scale down margin padding in preview to fit beautifully (e.g. margin / 3)
                            .padding(.top, CGFloat(settings.marginTop) / 3.0)
                            .padding(.bottom, CGFloat(settings.marginBottom) / 3.0)
                            .padding(.leading, CGFloat(settings.marginLeft) / 3.0)
                            .padding(.trailing, CGFloat(settings.marginRight) / 3.0)
                            .frame(width: 200, height: 120)
                        
                        Text("Usable Area")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                    }
                    .frame(width: 200, height: 120)
                }
                .padding(.trailing, 20)
            }
        }
    }
    
    private func marginStepper(_ label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label)
            Spacer()
            Stepper(value: value, in: 0...100, step: 5) {
                Text("\(value.wrappedValue) px")
                    .fontWeight(.semibold)
                    .frame(width: 60, alignment: .trailing)
            }
            .labelsHidden()
        }
    }
    
    // MARK: - Partitions Settings Tab
    private var partitionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Split Screen Partitions")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
            
            Text("Adjust partition split percentages below. Customize how much screen area halves and corners occupy.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 40) {
                // Partition Ratio Sliders
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Left / Right Partition:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(settings.partitionLeftRight * 100))% / \(100 - Int(settings.partitionLeftRight * 100))%")
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                        Slider(value: $settings.partitionLeftRight, in: 0.25...0.75, step: 0.05)
                            .tint(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Top / Bottom Partition:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(settings.partitionTopBottom * 100))% / \(100 - Int(settings.partitionTopBottom * 100))%")
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                        Slider(value: $settings.partitionTopBottom, in: 0.25...0.75, step: 0.05)
                            .tint(.purple)
                    }
                }
                .frame(width: 250)
                
                Spacer()
                
                // Real-time Partition slider line preview mockup!
                VStack(spacing: 8) {
                    Text("Interactive Partition Split")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        // Main Mock Screen
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.18), lineWidth: 2)
                            .frame(width: 200, height: 120)
                            .background(Color.primary.opacity(0.01))
                        
                        // Vertical Partition split line
                        Path { path in
                            path.move(to: CGPoint(x: 200 * settings.partitionLeftRight, y: 0))
                            path.addLine(to: CGPoint(x: 200 * settings.partitionLeftRight, y: 120))
                        }
                        .stroke(Color.purple, style: StrokeStyle(lineWidth: 1.8, dash: [2]))
                        
                        // Horizontal Partition split line
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 120 * settings.partitionTopBottom))
                            path.addLine(to: CGPoint(x: 200, y: 120 * settings.partitionTopBottom))
                        }
                        .stroke(Color.purple, style: StrokeStyle(lineWidth: 1.8, dash: [2]))
                    }
                    .frame(width: 200, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.trailing, 20)
            }
        }
    }
    
    // MARK: - Advanced Settings Tab
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Advanced Options")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Center Windows That Don't Resize Fully (e.g. small sizes)", isOn: $settings.centerUnresizable)
                    .toggleStyle(.checkbox)
                
                Toggle("Try To Keep Windows in Bounds (Clamped to Screen Edge)", isOn: $settings.keepInBounds)
                    .toggleStyle(.checkbox)
                
                Toggle("Resize Windows Proportionally on Multi-Monitor Shift", isOn: $settings.resizeProportionally)
                    .toggleStyle(.checkbox)
            }
            .padding(.bottom, 12)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 14) {
                Text("Center Resize Action Settings")
                    .fontWeight(.semibold)
                
                let centerAndResize = Binding<Bool>(
                    get: { UserDefaults.standard.bool(forKey: "centerAndResize") },
                    set: { UserDefaults.standard.set($0, forKey: "centerAndResize"); settings.saveSettings() }
                )
                
                Toggle("Resize Window When Centering", isOn: centerAndResize)
                    .toggleStyle(.checkbox)
                
                if centerAndResize.wrappedValue {
                    let centerAbsolute = Binding<Bool>(
                        get: { UserDefaults.standard.object(forKey: "centerAbsolute") == nil ? true : UserDefaults.standard.bool(forKey: "centerAbsolute") },
                        set: { UserDefaults.standard.set($0, forKey: "centerAbsolute"); settings.saveSettings() }
                    )
                    
                    Picker("Resize Mode:", selection: centerAbsolute) {
                        Text("Absolute Dimension (Pixels)").tag(true)
                        Text("Relative Dimension (% of Screen)").tag(false)
                    }
                    .pickerStyle(.radioGroup)
                    .horizontalRadioGroupLayout()
                    .padding(.leading, 20)
                    
                    if centerAbsolute.wrappedValue {
                        let w = Binding<Int>(
                            get: { UserDefaults.standard.integer(forKey: "centerAbsoluteWidth") == 0 ? 800 : UserDefaults.standard.integer(forKey: "centerAbsoluteWidth") },
                            set: { UserDefaults.standard.set($0, forKey: "centerAbsoluteWidth"); settings.saveSettings() }
                        )
                        let h = Binding<Int>(
                            get: { UserDefaults.standard.integer(forKey: "centerAbsoluteHeight") == 0 ? 600 : UserDefaults.standard.integer(forKey: "centerAbsoluteHeight") },
                            set: { UserDefaults.standard.set($0, forKey: "centerAbsoluteHeight"); settings.saveSettings() }
                        )
                        
                        HStack {
                            Text("Width:")
                            TextField("800", value: w, formatter: NumberFormatter())
                                .frame(width: 60)
                                .textFieldStyle(.roundedBorder)
                            Text("px")
                            
                            Spacer().frame(width: 20)
                            
                            Text("Height:")
                            TextField("600", value: h, formatter: NumberFormatter())
                                .frame(width: 60)
                                .textFieldStyle(.roundedBorder)
                            Text("px")
                        }
                        .padding(.leading, 24)
                    } else {
                        let pw = Binding<Double>(
                            get: { UserDefaults.standard.double(forKey: "centerRelativeWidth") == 0 ? 0.75 : UserDefaults.standard.double(forKey: "centerRelativeWidth") },
                            set: { UserDefaults.standard.set($0, forKey: "centerRelativeWidth"); settings.saveSettings() }
                        )
                        let ph = Binding<Double>(
                            get: { UserDefaults.standard.double(forKey: "centerRelativeHeight") == 0 ? 0.75 : UserDefaults.standard.double(forKey: "centerRelativeHeight") },
                            set: { UserDefaults.standard.set($0, forKey: "centerRelativeHeight"); settings.saveSettings() }
                        )
                        
                        HStack {
                            Text("Width (%):")
                            Slider(value: pw, in: 0.25...0.95, step: 0.05)
                                .frame(width: 120)
                            Text("\(Int(pw.wrappedValue * 100))%")
                                .fontWeight(.semibold)
                            
                            Spacer().frame(width: 25)
                            
                            Text("Height (%):")
                            Slider(value: ph, in: 0.25...0.95, step: 0.05)
                                .frame(width: 120)
                            Text("\(Int(ph.wrappedValue * 100))%")
                                .fontWeight(.semibold)
                        }
                        .padding(.leading, 24)
                    }
                }
            }
        }
    }
}

// MARK: - Unified Mini Layout Schematic Icon
struct MiniSchematicIcon: View {
    let action: WindowAction
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.1))
                .frame(width: 26, height: 26)
            
            if isLayoutAction {
                // Outer window representation outline
                RoundedRectangle(cornerRadius: 3.5)
                    .stroke(Color.blue, lineWidth: 1.5)
                    .frame(width: 15, height: 15)
                    .background(
                        filledRegion
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 3.5))
            } else {
                // Vector action representation glyph
                nonLayoutIcon
            }
        }
        .frame(width: 26, height: 26)
    }
    
    private var isLayoutAction: Bool {
        switch action {
        case .left, .right, .up, .down, .upperLeft, .upperRight, .lowerLeft, .lowerRight, .fullScreen, .center:
            return true
        default:
            return false
        }
    }
    
    @ViewBuilder
    private var filledRegion: some View {
        switch action {
        case .left:
            HStack(spacing: 0) {
                Color.blue.frame(width: 7.5)
                Spacer(minLength: 0)
            }
        case .right:
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                Color.blue.frame(width: 7.5)
            }
        case .up:
            VStack(spacing: 0) {
                Color.blue.frame(height: 7.5)
                Spacer(minLength: 0)
            }
        case .down:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Color.blue.frame(height: 7.5)
            }
        case .upperLeft:
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Color.blue.frame(width: 7.5, height: 7.5)
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
        case .upperRight:
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Color.blue.frame(width: 7.5, height: 7.5)
                }
                Spacer(minLength: 0)
            }
        case .lowerLeft:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    Color.blue.frame(width: 7.5, height: 7.5)
                    Spacer(minLength: 0)
                }
            }
        case .lowerRight:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Color.blue.frame(width: 7.5, height: 7.5)
                }
            }
        case .fullScreen:
            Color.blue
        case .center:
            ZStack {
                Color.clear
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var nonLayoutIcon: some View {
        switch action {
        case .snapBack:
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.blue)
        case .prevMonitor:
            Image(systemName: "arrow.left.square.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.blue)
        case .nextMonitor:
            Image(systemName: "arrow.right.square.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.blue)
        case .spacePrev:
            Image(systemName: "arrow.left.to.line")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.blue)
        case .spaceNext:
            Image(systemName: "arrow.right.to.line")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.blue)
        default:
            EmptyView()
        }
    }
}
