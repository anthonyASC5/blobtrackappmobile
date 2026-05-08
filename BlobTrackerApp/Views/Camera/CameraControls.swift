import SwiftUI

struct CameraControls: View {
    @ObservedObject var viewModel: CameraViewModel
    @ObservedObject var settingsStore: TrackingSettingsStore
    @State private var isExpanded = false
    @State private var selectedCameraType: CameraType = .wide
    @State private var activeTool: AdjustmentTool = .threshold
    @State private var isBlobParametersExpanded = false
    @State private var isEditorExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            topBar

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Button(action: viewModel.toggleTracking) {
                            Label(
                                viewModel.isTrackingEnabled ? "Tracking..." : "Paused",
                                systemImage: viewModel.isTrackingEnabled ? "target" : "pause.circle"
                            )
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Picker("Mode", selection: $settingsStore.settings.detectionMode) {
                            ForEach(DetectionMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    HStack(spacing: 12) {
                        Button(action: viewModel.flipCamera) {
                            Label("Flip Camera", systemImage: "camera.rotate")
                        }
                        .buttonStyle(.bordered)

                        Picker("Lens", selection: $selectedCameraType) {
                            Text("1x").tag(CameraType.wide)
                            Text("0.5x").tag(CameraType.ultraWide)
                        }
                        .pickerStyle(.segmented)
                        .disabled(viewModel.cameraPosition == .front)
                        .onChange(of: selectedCameraType) { _, newType in
                            viewModel.setCameraType(newType)
                        }

                        BlobColorModeButton(
                            mode: settingsStore.settings.blobColorMode,
                            title: settingsStore.settings.blobColorMode.displayName
                        ) {
                            settingsStore.settings.blobColorMode = nextBlobColorMode()
                        }
                        .frame(width: 108)
                    }

                    adjustmentGroups

                    sliderPanel

                    fxStrip
                }
            }

            HStack {
                Spacer()
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
        }
        .onChange(of: viewModel.cameraPosition) { _, newPosition in
            if newPosition == .front {
                selectedCameraType = .wide
            }
        }
        .onAppear {
            if activeTool == .auto {
                activeTool = .threshold
            }
        }
        .onChange(of: settingsStore.settings.detectionMode) { _, newMode in
            if newMode == .motion {
                applyMotionDefaults()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("ADJUST")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.pink)
                .tracking(2.2)

            Spacer()

            Menu {
                Button("Reset Defaults", role: .destructive) {
                    resetAll()
                }
                Button("Auto Adjust") {
                    applyAutoAdjust()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.12), in: Circle())
            }
        }
    }

    private var adjustmentGroups: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Blob tools change detection output, while editor tools change the preview look.
            parameterGroupHeader(
                title: "Blob Parameters",
                isExpanded: isBlobParametersExpanded
            ) {
                isBlobParametersExpanded.toggle()
            }

            if isBlobParametersExpanded {
                chipRow(for: blobParameterTools)
            }

            parameterGroupHeader(
                title: "Video Editor",
                isExpanded: isEditorExpanded
            ) {
                isEditorExpanded.toggle()
            }

            if isEditorExpanded {
                chipRow(for: editorTools)
            }
        }
    }

    private func chipRow(for tools: [AdjustmentTool]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tools) { tool in
                    Button {
                        select(tool)
                    } label: {
                        adjustmentChip(for: tool)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var sliderPanel: some View {
        let tool = activeTool
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tool.title)
                    .font(.headline.weight(.semibold))
                Spacer()
                Text(tool.readout(in: settingsStore.settings))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { tool.normalizedValue(in: settingsStore.settings) },
                    set: { tool.setNormalizedValue($0, in: &settingsStore.settings) }
                ),
                in: -100...100
            )
            .tint(Color.pink)

            HStack {
                Text("-100")
                Spacer()
                Text("0")
                Spacer()
                Text("100")
            }
            .font(.caption2.monospaced())
            .foregroundStyle(.secondary.opacity(0.8))
        }
        .padding(.top, 2)
    }

    private var fxStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FX / Presets")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .tracking(1.2)

            // These buttons are quick-look presets for the live preview look.
            HStack(spacing: 8) {
                fxButton(
                    title: "Off",
                    symbol: "sparkles.slash",
                    isSelected: settingsStore.settings.visualEffectMode == .off
                ) {
                    settingsStore.settings.visualEffectMode = .off
                }

                fxButton(
                    title: "FX 1",
                    symbol: "eyeglasses",
                    isSelected: settingsStore.settings.visualEffectMode == .nightVision
                ) {
                    settingsStore.settings.visualEffectMode = .nightVision
                }

                fxButton(
                    title: "FX 2",
                    symbol: "dot.radiowaves.left.and.right",
                    isSelected: settingsStore.settings.visualEffectMode == .lidarScan
                ) {
                    settingsStore.settings.visualEffectMode = .lidarScan
                }

                fxButton(
                    title: "FX 3",
                    symbol: "sparkles",
                    isSelected: isMotionFX3Active
                ) {
                    applyMotionDefaults()
                }
            }
        }
        .padding(.top, 4)
    }

    private func parameterGroupHeader(title: String, isExpanded: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.headline.weight(.semibold))
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(isExpanded ? .white : .black)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background {
                Capsule(style: .continuous)
                    .fill(
                        isExpanded
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [Color.pink, Color(red: 1.0, green: 0.34, blue: 0.55)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        : AnyShapeStyle(Color.white)
                    )
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(isExpanded ? 0.0 : 0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(isExpanded ? 0.08 : 0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func fxButton(title: String, symbol: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? .white : .primary)
            .background {
                Capsule(style: .continuous)
                    .fill(
                        isSelected
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [Color.black, Color(red: 0.0, green: 0.45, blue: 0.12)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        : AnyShapeStyle(Color.white.opacity(0.12))
                    )
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(isSelected ? Color.green.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func adjustmentChip(for tool: AdjustmentTool) -> some View {
        let isActive = tool.isHighlighted(using: settingsStore.settings, activeTool: activeTool)

        return VStack(spacing: 5) {
            Image(systemName: tool.symbol)
                .font(.system(size: 14, weight: .semibold))

            if isActive {
                Text(tool.title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(isActive ? .white : .primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(minWidth: 52)
        .background {
            Capsule(style: .continuous)
                .fill(
                    isActive
                    ? tool.activeFill
                    : AnyShapeStyle(Color.white.opacity(0.10))
                )
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(isActive ? Color.clear : Color.white.opacity(0.10), lineWidth: 1)
        }
    }

    private func select(_ tool: AdjustmentTool) {
        switch tool {
        case .auto:
            applyAutoAdjust()
            activeTool = .brightness
            isBlobParametersExpanded = true
            isEditorExpanded = true
        case .boundingBoxes:
            settingsStore.settings.showBoundingBoxes.toggle()
            isBlobParametersExpanded = true
        case .lines:
            settingsStore.settings.showTrails.toggle()
            isBlobParametersExpanded = true
        case .circles:
            settingsStore.settings.showBlobCircles.toggle()
            isBlobParametersExpanded = true
        case .threshold, .minArea:
            activeTool = tool
            isBlobParametersExpanded = true
        case .brightness, .contrast, .saturation, .sharpness, .gamma, .hueShift:
            activeTool = tool
            isEditorExpanded = true
        case .glow:
            activeTool = tool
            isEditorExpanded = true
        default:
            activeTool = tool
        }
    }

    private func applyAutoAdjust() {
        settingsStore.settings.threshold = 148
        settingsStore.settings.minimumBlobArea = 18
        settingsStore.settings.brightness = 0.03
        settingsStore.settings.contrast = 1.10
        settingsStore.settings.saturation = 1.06
        settingsStore.settings.sharpness = 0.10
        settingsStore.settings.gamma = 0.98
        settingsStore.settings.hueShift = 0
        settingsStore.settings.glow = 50
    }

    private func applyMotionDefaults() {
        settingsStore.settings.applyMotionDefaults()
        activeTool = .glow
        isEditorExpanded = true
        isBlobParametersExpanded = true
    }

    private func resetAll() {
        settingsStore.reset()
        settingsStore.settings.visualEffectMode = .off
        viewModel.resetTracking()
        selectedCameraType = .wide
        activeTool = .threshold
        isExpanded = false
        isBlobParametersExpanded = false
        isEditorExpanded = false
    }

    private func nextBlobColorMode() -> BlobColorMode {
        switch settingsStore.settings.blobColorMode {
        case .white:
            return .rainbow
        case .rainbow:
            return .red
        case .red:
            return .neonBlue
        case .neonBlue:
            return .white
        }
    }

    private var blobParameterTools: [AdjustmentTool] {
        [.auto, .threshold, .minArea, .boundingBoxes, .lines, .circles]
    }

    private var editorTools: [AdjustmentTool] {
        [.brightness, .contrast, .saturation, .sharpness, .gamma, .hueShift, .glow]
    }

    private var isMotionFX3Active: Bool {
        settingsStore.settings.blackAndWhite
        && settingsStore.settings.blobColorMode == .white
        && settingsStore.settings.contrast >= 1.7
        && settingsStore.settings.glow >= 80
    }
}

private enum AdjustmentTool: String, CaseIterable, Identifiable {
    case auto
    case threshold
    case minArea
    case boundingBoxes
    case lines
    case circles
    case brightness
    case contrast
    case saturation
    case sharpness
    case gamma
    case hueShift
    case glow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: return "Auto"
        case .threshold: return "Threshold"
        case .minArea: return "Min Area"
        case .boundingBoxes: return "Boxes"
        case .lines: return "Lines"
        case .circles: return "Circles"
        case .brightness: return "Brightness"
        case .contrast: return "Contrast"
        case .saturation: return "Saturation"
        case .sharpness: return "Sharpness"
        case .gamma: return "Gamma"
        case .hueShift: return "Hue"
        case .glow: return "Glow"
        }
    }

    var symbol: String {
        switch self {
        case .auto: return "wand.and.sparkles"
        case .threshold: return "slider.horizontal.3"
        case .minArea: return "square.dashed"
        case .boundingBoxes: return "rectangle.dashed"
        case .lines: return "line.diagonal"
        case .circles: return "circle.dashed"
        case .brightness: return "sun.max"
        case .contrast: return "circle.lefthalf.filled"
        case .saturation: return "drop"
        case .sharpness: return "sparkle"
        case .gamma: return "function"
        case .hueShift: return "paintpalette"
        case .glow: return "burst"
        }
    }

    var activeFill: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [Color.pink, Color(red: 1.0, green: 0.34, blue: 0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    func isHighlighted(using settings: TrackingSettings, activeTool: AdjustmentTool) -> Bool {
        if self == activeTool {
            return true
        }
        switch self {
        case .boundingBoxes:
            return settings.showBoundingBoxes
        case .lines:
            return settings.showTrails
        case .circles:
            return settings.showBlobCircles
        default:
            return false
        }
    }

    func readout(in settings: TrackingSettings) -> String {
        switch self {
        case .auto:
            return "Ready"
        case .threshold:
            return "\(Int(settings.threshold.rounded()))"
        case .minArea:
            return "\(settings.minimumBlobArea)"
        case .boundingBoxes:
            return settings.showBoundingBoxes ? "On" : "Off"
        case .lines:
            return settings.showTrails ? "On" : "Off"
        case .circles:
            return settings.showBlobCircles ? "On" : "Off"
        case .brightness:
            return String(format: "%.2f", settings.brightness)
        case .contrast:
            return String(format: "%.2f", settings.contrast)
        case .saturation:
            return String(format: "%.2f", settings.saturation)
        case .sharpness:
            return String(format: "%.2f", settings.sharpness)
        case .gamma:
            return String(format: "%.2f", settings.gamma)
        case .hueShift:
            return String(format: "%.0f", settings.hueShift)
        case .glow:
            return String(format: "%.0f", settings.glow)
        }
    }

    func normalizedValue(in settings: TrackingSettings) -> Double {
        switch self {
        case .threshold:
            return Self.normalize(settings.threshold, from: 0...255)
        case .minArea:
            return Self.normalize(Double(settings.minimumBlobArea), from: 1...400)
        case .brightness:
            return Self.normalize(settings.brightness, from: -0.5...0.5)
        case .contrast:
            return Self.normalize(settings.contrast, from: 0.5...2.0)
        case .saturation:
            return Self.normalize(settings.saturation, from: 0.0...2.0)
        case .sharpness:
            return Self.normalize(settings.sharpness, from: 0.0...2.0)
        case .gamma:
            return Self.normalize(settings.gamma, from: 0.25...3.0)
        case .hueShift:
            return Self.normalize(settings.hueShift, from: -180...180)
        case .glow:
            return Self.normalize(settings.glow, from: 0...100)
        default:
            return 0
        }
    }

    func setNormalizedValue(_ value: Double, in settings: inout TrackingSettings) {
        switch self {
        case .threshold:
            settings.threshold = Self.denormalize(value, to: 0...255)
        case .minArea:
            settings.minimumBlobArea = Int(Self.denormalize(value, to: 1...400).rounded())
        case .brightness:
            settings.brightness = Self.denormalize(value, to: -0.5...0.5)
        case .contrast:
            settings.contrast = Self.denormalize(value, to: 0.5...2.0)
        case .saturation:
            settings.saturation = Self.denormalize(value, to: 0.0...2.0)
        case .sharpness:
            settings.sharpness = Self.denormalize(value, to: 0.0...2.0)
        case .gamma:
            settings.gamma = max(Self.denormalize(value, to: 0.25...3.0), 0.01)
        case .hueShift:
            settings.hueShift = Self.denormalize(value, to: -180...180)
        case .glow:
            settings.glow = Self.denormalize(value, to: 0...100)
        default:
            break
        }
    }

    private static func normalize(_ value: Double, from range: ClosedRange<Double>) -> Double {
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        let progress = (clamped - range.lowerBound) / (range.upperBound - range.lowerBound)
        return (progress * 200) - 100
    }

    private static func denormalize(_ value: Double, to range: ClosedRange<Double>) -> Double {
        let clamped = min(max(value, -100), 100)
        let progress = (clamped + 100) / 200
        return range.lowerBound + (progress * (range.upperBound - range.lowerBound))
    }
}
