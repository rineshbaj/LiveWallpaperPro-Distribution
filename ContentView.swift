import SwiftUI

// MARK: - Root Content View (Fully Responsive)

struct ContentView: View {
    @EnvironmentObject var manager: WallpaperManager
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var license: LicenseManager

    @State private var activeOverlay: OverlayType? = nil
    @State private var isHoveringClock = false

    enum OverlayType: Equatable { case settings, library }

    var body: some View {
        GeometryReader { geo in
            ZStack {

                // ── 1. FULL-BLEED CENTERED BACKGROUND ────────────────────
                wallpaperBackground(geo: geo)

                // ── 2. NAV ARROWS — always visible ─────────────────────────────
                HStack {
                    if manager.urls.count > 1 {
                        ArrowButton(icon: "chevron.left") { manager.prev() }
                    }
                    Spacer()
                    if manager.urls.count > 1 {
                        ArrowButton(icon: "chevron.right") { manager.next() }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, geo.size.width < 600 ? 12 : 28)

                // ── 3. BOTTOM DOCK ────────────────────────────────────────
                VStack {
                    if manager.showPerformanceStats {
                        PerformanceStatsOverlay()
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.top, 10)
                    }
                    
                    Spacer()
                    bottomDock
                        .scaleEffect(geo.size.width < 600 ? 0.85 : 1.0)
                        .padding(.bottom, geo.size.height < 500 ? 16 : 36)
                }

                // ── 4. OVERLAYS ───────────────────────────────────────────
                if activeOverlay != nil {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35)) { activeOverlay = nil }
                        }
                        .transition(.opacity)
                        .zIndex(1)
                }

                if activeOverlay == .settings {
                    GlassOverlay(
                        title: "Settings", icon: "gearshape.fill", geo: geo,
                        onClose: { withAnimation(.spring(response: 0.35)) { activeOverlay = nil } }
                    ) { AppSettingsView() }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96).combined(with: .opacity),
                        removal:   .scale(scale: 0.96).combined(with: .opacity)
                    ))
                    .zIndex(2)
                }

                if activeOverlay == .library {
                    GlassOverlay(
                        title: "Gallery", icon: "photo.on.rectangle.angled", geo: geo,
                        onClose: { withAnimation(.spring(response: 0.35)) { activeOverlay = nil } }
                    ) { LibraryView() }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96).combined(with: .opacity),
                        removal:   .scale(scale: 0.96).combined(with: .opacity)
                    ))
                    .zIndex(2)
                }
            }
        }
        .frame(minWidth: 680, minHeight: 480)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: activeOverlay)
    }

    // ── Wallpaper background: exact-size frame prevents left-anchor crop ──
    @ViewBuilder
    private func wallpaperBackground(geo: GeometryProxy) -> some View {
        ZStack {
            if let thumb = manager.currentThumbnail {
                Image(nsImage: thumb)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .clipped()
            } else {
                ZStack {
                    Color(NSColor.windowBackgroundColor)
                    VStack(spacing: 14) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 52, weight: .ultraLight))
                        Text("Open Gallery to add wallpapers")
                            .font(.system(size: 15, weight: .light))
                    }
                    .foregroundColor(.secondary)
                }
            }

            // ── Interactive Clock Preview ──────────────────────────────────
            if manager.showClock {
                ClockView(manager: manager)
                    .scaleEffect(manager.clockScale)
                    .position(
                        x: geo.size.width * manager.clockX,
                        y: geo.size.height * manager.clockY
                    )
                    // 1. Move (Drag)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newX = value.location.x / geo.size.width
                                let newY = value.location.y / geo.size.height
                                manager.clockX = max(0.05, min(0.95, newX))
                                manager.clockY = max(0.05, min(0.95, newY))
                            }
                    )
                    // 2. Scale (Pinch)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / 1.5
                                manager.clockScale = max(0.4, min(3.0, manager.clockScale * delta))
                            }
                    )
                    // 3. Cycle Style (Double Tap)
                    .onTapGesture(count: 2) {
                        let allStyles = ClockStyle.allCases
                        if let index = allStyles.firstIndex(of: manager.clockStyle) {
                            let nextIndex = (index + 1) % allStyles.count
                            withAnimation(.spring(response: 0.35)) {
                                manager.clockStyle = allStyles[nextIndex]
                            }
                        }
                    }
                    // Visual feedback & Mini Toolbar
                    .overlay(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(isHoveringClock ? 0.3 : 0.1), lineWidth: 1)
                                .padding(-30)
                            
                            if isHoveringClock && activeOverlay == nil {
                                ClockControlToolbar(manager: manager)
                                    .offset(y: 80) // Positioned below the clock
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                        }
                        .opacity(activeOverlay == nil ? 1 : 0)
                    )
                    .onHover { isHoveringClock = $0 }
            }
        }
        .ignoresSafeArea()
    }

    private var bottomDock: some View {
        HStack(spacing: 6) {
            DockButton(icon: "photo.on.rectangle.angled", label: "Gallery", isActive: activeOverlay == .library) {
                withAnimation(.spring(response: 0.35)) {
                    activeOverlay = activeOverlay == .library ? nil : .library
                }
            }

            Rectangle()
                .fill(Color.primary.opacity(0.15))
                .frame(width: 1, height: 20)

            DockButton(icon: "gearshape.fill", label: "Settings", isActive: activeOverlay == .settings) {
                withAnimation(.spring(response: 0.35)) {
                    activeOverlay = activeOverlay == .settings ? nil : .settings
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.25), radius: 24, y: 8)
    }
}

// MARK: - Arrow Button

struct ArrowButton: View {
    let icon: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.25)) { action() } }) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.black.opacity(isHovering ? 0.55 : 0.35))
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                )
                .scaleEffect(isHovering ? 1.12 : 1.0)
                .animation(.spring(response: 0.25), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Dock Button

struct DockButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                if isActive || isHovering {
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .foregroundStyle(isActive ? Color.primary : Color.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isActive ? Color.primary.opacity(0.12) : Color.clear,
                in: Capsule()
            )
            .animation(.spring(response: 0.3), value: isActive || isHovering)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Glass Overlay (Responsive to window size)

struct GlassOverlay<Content: View>: View {
    @EnvironmentObject var manager: WallpaperManager
    let title: String
    let icon: String
    let geo: GeometryProxy
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content

    var overlayWidth:  CGFloat { min(geo.size.width  * 0.80, 780) }
    var overlayHeight: CGFloat { min(geo.size.height * 0.85, 620) }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 26, height: 26)
                        .background(Color.primary.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 18)

            Divider().opacity(0.4)

            content()
        }
        .frame(width: overlayWidth, height: overlayHeight)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .opacity(manager.isInteractingWithSettings ? 0.2 : 1.0)
        .shadow(color: .black.opacity(manager.isInteractingWithSettings ? 0.05 : 0.3), radius: 40, y: 20)
        .animation(.easeInOut(duration: 0.25), value: manager.isInteractingWithSettings)
    }
}

// MARK: - Settings View

struct AppSettingsView: View {
    @EnvironmentObject var manager: WallpaperManager
    @EnvironmentObject var license: LicenseManager
    @State private var showFileImporter = false
    @State private var licenseInput: String = ""
    @State private var showProAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // ── DISPLAYS (Multi-Monitor support) ──────────────────────
                SettingSection(title: "DISPLAYS") {
                    ForEach(0..<NSScreen.screens.count, id: \.self) { i in
                        let screen = NSScreen.screens[i]
                        let screenID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.stringValue ?? "\(i)"
                        
                        SettingRow(icon: "display", label: i == 0 ? "Main Display" : "External Display \(i)") {
                            Toggle("", isOn: Binding(
                                get: { manager.activeDisplayIDs.isEmpty || manager.activeDisplayIDs.contains(screenID) },
                                set: { v in
                                    if v {
                                        manager.activeDisplayIDs.insert(screenID)
                                    } else {
                                        manager.activeDisplayIDs.remove(screenID)
                                    }
                                }
                            ))
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                        if i < NSScreen.screens.count - 1 { SettingDivider() }
                    }
                }

                Spacer().frame(height: 16)

                // ── LIVE DESKTOP (Pro only) ────────────────────────────────
                SettingSection(title: "LIVE DESKTOP") {
                    SettingRow(icon: "display", label: "Enable Live Desktop") {
                        HStack(spacing: 8) {
                            if !license.isPro {
                                // Pro badge
                                Text("PRO")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.orange, in: Capsule())
                            }
                            Toggle("", isOn: Binding(
                                get: { manager.isWallpaperActive },
                                set: { v in
                                    if license.isPro {
                                        manager.isWallpaperActive = v
                                    } else {
                                        showProAlert = true
                                    }
                                }
                            ))
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                    }
                    SettingDivider()
                    SettingRow(icon: "arrow.triangle.2.circlepath", label: "Change Picture Every") {
                        Picker("", selection: $manager.selectedInterval) {
                            ForEach(PlaylistInterval.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 140)
                    }
                }

                Spacer().frame(height: 16)

                // ── CLOCK STYLE + POSITION ───────────────────────────────────────
                ClockEditorSection()

                // ── POWER ──────────────────────────────────────────────────
                SettingSection(title: "POWER & SCREENSAVER") {
                    SettingRow(icon: "moon.fill", label: "Auto-Screensaver") {
                        Toggle("", isOn: $manager.isIdleModeEnabled)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    SettingDivider()
                    SettingRow(icon: "battery.50", label: "Pause on Battery") {
                        Toggle("", isOn: $manager.pauseOnBattery)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    SettingDivider()
                    SettingRow(icon: "timer", label: "Idle Timeout") {
                        HStack(spacing: 8) {
                            Text("\(manager.idleTimeoutMinutes) min")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                            Stepper("", value: $manager.idleTimeoutMinutes, in: 1...120)
                                .labelsHidden()
                        }
                    }
                    SettingDivider()
                    SettingRow(icon: "play.rectangle", label: "Preview Screensaver") {
                        Button("Preview") { manager.showIdleWindow() }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.blue)
                    }
                }

                Spacer().frame(height: 16)

                // ── LICENSE ────────────────────────────────────────────────
                SettingSection(title: "LICENSE") {
                    if license.isPro {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pro Lifetime Active")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("All features unlocked")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                    } else {
                        VStack(spacing: 14) {
                            // Upgrade CTA
                            VStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.orange)
                                Text("Unlock Live Desktop")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("The gallery & wallpaper library are free.\nUpgrade to set live wallpapers on your desktop.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 8)

                            Button {
                                NSWorkspace.shared.open(URL(string: "https://yourdomain.com#pricing")!)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.up.right.circle.fill")
                                    Text("Upgrade to Pro — $9.99")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)

                            Divider().opacity(0.4)

                            HStack(spacing: 8) {
                                Image(systemName: "key.fill")
                                    .foregroundStyle(.secondary)
                                SecureField("Enter license key…", text: $licenseInput)
                                    .font(.system(size: 13))
                                Button("Activate") { license.activate(key: licenseInput) }
                                    .buttonStyle(.bordered)
                                    .disabled(license.isValidating || licenseInput.isEmpty)
                                    .controlSize(.small)
                            }

                            if let error = license.lastError {
                                Text(error)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                    }
                }

                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .alert("Upgrade to Pro", isPresented: $showProAlert) {
            Button("Upgrade — $9.99") {
                NSWorkspace.shared.open(URL(string: "https://yourdomain.com#pricing")!)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Setting a live desktop wallpaper requires the Pro upgrade. The gallery and all other features are completely free!")
        }
    }
}

// MARK: - Minimal Setting Components

struct SettingSection<Content: View>: View {
    let title: String
    @EnvironmentObject var manager: WallpaperManager
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(1.2)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .onTapGesture(count: 3) {
                    withAnimation(.spring()) {
                        manager.showPerformanceStats.toggle()
                    }
                }

            VStack(spacing: 0) {
                content()
            }
            .background(.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

struct SettingRow<Trailing: View>: View {
    let icon: String
    let label: String
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.blue)
                .frame(width: 28, height: 28)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.primary)

            Spacer()

            trailing()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
    }
}

struct SettingDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 58)
            .opacity(0.35)
    }
}

// MARK: - Interactive Clock Editor

struct ClockEditorSection: View {
    @EnvironmentObject var manager: WallpaperManager

    // 3×3 grid anchor points mapped to clockX / clockY
    private let positions: [(label: String, x: CGFloat, y: CGFloat)] = [
        ("↖", 0.15, 0.15), ("↑",  0.50, 0.15), ("↗", 0.85, 0.15),
        ("←", 0.15, 0.50), ("•",  0.50, 0.50), ("→", 0.85, 0.50),
        ("↙", 0.15, 0.85), ("↓",  0.50, 0.85), ("↘", 0.85, 0.85),
    ]

    private var currentPositionIndex: Int {
        positions.firstIndex { abs($0.x - manager.clockX) < 0.05 && abs($0.y - manager.clockY) < 0.05 } ?? -1
    }

    var body: some View {
        SettingSection(title: "CLOCK") {
            VStack(spacing: 0) {

                // ── Style scroll ─────────────────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.blue)
                            .frame(width: 28, height: 28)
                            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                        Text("Style")
                            .font(.system(size: 14))
                        Spacer()
                        Text(manager.clockStyle.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(ClockStyle.allCases) { style in
                                ClockStyleCard(style: style, isSelected: manager.clockStyle == style) {
                                    withAnimation(.spring(response: 0.3)) {
                                        manager.clockStyle = style
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 14)
                    }
                }

                Divider().padding(.leading, 18).opacity(0.35)

                // ── Position grid ─────────────────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "move.3d")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.purple)
                            .frame(width: 28, height: 28)
                            .background(Color.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                        Text("Position")
                            .font(.system(size: 14))
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)

                    // Mini wallpaper preview with 3x3 grid
                    HStack(spacing: 16) {
                        // Visual mini-map
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 150, height: 95)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 4) {
                                ForEach(positions.indices, id: \.self) { i in
                                    let pos = positions[i]
                                    let selected = currentPositionIndex == i

                                    Circle()
                                        .fill(selected ? Color.blue : Color.white.opacity(0.3))
                                        .overlay(
                                            Circle()
                                                .stroke(selected ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                        .frame(width: selected ? 18 : 12, height: selected ? 18 : 12)
                                        .scaleEffect(selected ? 1.2 : 1.0)
                                        .animation(.spring(response: 0.25), value: selected)
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3)) {
                                                manager.clockX = pos.x
                                                manager.clockY = pos.y
                                            }
                                        }
                                }
                            }
                            .padding(14)
                        }

                        // Label grid buttons
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                            ForEach(positions.indices, id: \.self) { i in
                                let pos = positions[i]
                                let selected = currentPositionIndex == i

                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        manager.clockX = pos.x
                                        manager.clockY = pos.y
                                    }
                                } label: {
                                    Text(pos.label)
                                        .font(.system(size: 16))
                                        .frame(width: 34, height: 34)
                                        .background(
                                            selected
                                                ? Color.blue.opacity(0.85)
                                                : Color.primary.opacity(0.06),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                        .foregroundStyle(selected ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
                }

                Divider().padding(.leading, 18).opacity(0.35)

                // ── Scale slider ──────────────────────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.orange)
                            .frame(width: 28, height: 28)
                            .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                        Text("Scale")
                            .font(.system(size: 14))
                        Spacer()
                        Text("\(Int(manager.clockScale * 100))%")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $manager.clockScale, in: 0.5...2.5) {
                        Text("Scale")
                    } onEditingChanged: { editing in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            manager.isInteractingWithSettings = editing
                        }
                    }
                    .tint(.orange)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
        }
    }
}

// MARK: - Clock Style Card

struct ClockStyleCard: View {
    let style: ClockStyle
    let isSelected: Bool
    let action: () -> Void

    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Mini preview card
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.65))
                    miniClock
                        .scaleEffect(0.28)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
                .frame(width: 96, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? Color.blue : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
                )

                Text(style.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
        }
        .buttonStyle(.plain)
        .onReceive(timer) { currentTime = $0 }
    }

    @ViewBuilder
    private var miniClock: some View {
        switch style {
        case .modern:
            VStack(spacing: 0) {
                Text(currentTime, style: .time)
                    .font(.system(size: 120, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                Text(currentTime, format: .dateTime.weekday().month().day())
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white.opacity(0.7))
            }
        case .classic:
            Text(currentTime, style: .time)
                .font(.system(size: 140, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        case .minimal:
            HStack {
                Text(currentTime, style: .time)
                    .font(.system(size: 40, weight: .medium, design: .rounded))
                Text("|")
                Text(currentTime, format: .dateTime.weekday())
                    .font(.system(size: 20, weight: .light))
            }
            .foregroundColor(.white)
            .padding(20)
            .background(Color.black.opacity(0.2))
            .cornerRadius(10)
        case .futuristic:
            VStack(spacing: 8) {
                Text(currentTime, format: .dateTime.weekday())
                    .font(.system(size: 80, weight: .bold, design: .monospaced))
                    .textCase(.uppercase)
                    .tracking(8)
                Text(currentTime, style: .time)
                    .font(.system(size: 28, weight: .medium))
            }
            .foregroundColor(.white)
        case .ios:
            VStack(spacing: -15) {
                Text(currentTime, format: .dateTime.weekday().month().day())
                    .font(.system(size: 24, weight: .medium))
                Text(currentTime, style: .time)
                    .font(.system(size: 180, weight: .medium, design: .rounded))
            }
            .foregroundColor(.white)
        }
    }
}
// MARK: - Clock Control Toolbar (For Mouse/Mac Mini users)

struct ClockControlToolbar: View {
    @ObservedObject var manager: WallpaperManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Style Cycler
            Button(action: {
                let allStyles = ClockStyle.allCases
                if let index = allStyles.firstIndex(of: manager.clockStyle) {
                    let nextIndex = (index + 1) % allStyles.count
                    withAnimation(.spring(response: 0.3)) {
                        manager.clockStyle = allStyles[nextIndex]
                    }
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "clock.arrow.2.circlepath")
                    Text("Style").font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
            // Mini Scale Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10))
                    Text("Size").font(.system(size: 9, weight: .bold))
                    Spacer()
                    Text("\(Int(manager.clockScale * 100))%")
                        .font(.system(size: 9, design: .monospaced))
                }
                .foregroundStyle(.white.opacity(0.8))
                
                Slider(value: $manager.clockScale, in: 0.5...2.5)
                    .controlSize(.mini)
                    .tint(.white)
            }
            .padding(.horizontal, 12)
            .frame(width: 140, height: 44)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(8)
        .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
}

// ── Performance Stats Overlay ──────────────────────────────────────────────
struct PerformanceStatsOverlay: View {
    @EnvironmentObject var manager: WallpaperManager
    
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .foregroundStyle(.green)
                Text(String(format: "%.1f%%", manager.cpuUsage))
                    .monospacedDigit()
            }
            
            Divider().frame(height: 12).background(Color.white.opacity(0.2))
            
            HStack(spacing: 6) {
                Image(systemName: "memorychip")
                    .foregroundStyle(.blue)
                Text(String(format: "%.0f MB", manager.ramUsageMB))
                    .monospacedDigit()
            }
            
            Divider().frame(height: 12).background(Color.white.opacity(0.2))
            
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.green)
                Text("Zero-Drain Active")
                    .font(.system(size: 11, weight: .semibold))
            }
        }
        .font(.system(size: 12, weight: .medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
        .padding(.bottom, 20)
    }
}
