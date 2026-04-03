import SwiftUI  // Import for SwiftUI

struct CameraControls: View {  // View for camera controls
    @ObservedObject var viewModel: CameraViewModel  // Observed view model
    @ObservedObject var settingsStore: TrackingSettingsStore  // Observed settings
    @State private var isExpanded = true  // State for expanded HUD
    @State private var selectedCameraType: CameraType = .wide  // State for lens type

    var body: some View {  // Body of view
        VStack(alignment: .leading, spacing: 14) {  // VStack for layout
            if isExpanded {  // Conditional for expanded
                HStack(spacing: 12) {  // HStack for top row
                    Button(action: viewModel.toggleTracking) {  // Button to toggle tracking
                        Label(  // Label with text and icon
                            viewModel.isTrackingEnabled ? "Tracking On" : "Tracking Off",
                            systemImage: viewModel.isTrackingEnabled ? "dot.scope" : "pause.circle"
                        )
                        .font(.headline)  // Font
                        .padding(.horizontal, 14)  // Padding
                        .padding(.vertical, 10)  // Padding
                        .frame(maxWidth: .infinity)  // Frame
                    }
                    .buttonStyle(.borderedProminent)  // Style

                    Picker("Mode", selection: $settingsStore.settings.detectionMode) {  // Picker for detection mode
                        ForEach(DetectionMode.allCases) { mode in  // For each mode
                            Text(mode.displayName).tag(mode)  // Text with tag
                        }
                    }
                    .pickerStyle(.segmented)  // Segmented style
                }

                HStack(spacing: 12) {  // HStack for camera controls
                    Button(action: viewModel.flipCamera) {  // Button to flip camera (front/back)
                        Label("Flip Camera", systemImage: "camera.rotate")  // Label
                    }
                    .buttonStyle(.bordered)  // Style

                    Picker("Lens", selection: $selectedCameraType) {  // Picker for lens type
                        Text("1x").tag(CameraType.wide)  // Wide 1x option
                        Text("0.5x").tag(CameraType.ultraWide)  // Ultra wide 0.5x option
                    }
                    .pickerStyle(.segmented)  // Segmented
                    .disabled(viewModel.cameraPosition == .front)  // Disable ultra-wide for selfie
                    .onChange(of: selectedCameraType) { type in
                        viewModel.setCameraType(type)  // Set camera type when changed
                    }
                }

                VStack(alignment: .leading, spacing: 8) {  // VStack for tracking sliders
                    sliderRow(
                        title: "Threshold",
                        value: Binding(
                            get: { settingsStore.settings.threshold },
                            set: { settingsStore.settings.threshold = $0 }
                        ),
                        range: 0...255
                    )

                    sliderRow(
                        title: "Min Area",
                        value: Binding(
                            get: { Double(settingsStore.settings.minimumBlobArea) },
                            set: { settingsStore.settings.minimumBlobArea = Int($0.rounded()) }
                        ),
                        range: 1...400
                    )

                    // Effects controls under min area
                    sliderRow(
                        title: "Brightness",
                        value: Binding(
                            get: { settingsStore.settings.brightness },
                            set: { settingsStore.settings.brightness = $0 }
                        ),
                        range: -0.5...0.5
                    )

                    sliderRow(
                        title: "Contrast",
                        value: Binding(
                            get: { settingsStore.settings.contrast },
                            set: { settingsStore.settings.contrast = $0 }
                        ),
                        range: 0.5...2.0
                    )

                    sliderRow(
                        title: "Saturation",
                        value: Binding(
                            get: { settingsStore.settings.saturation },
                            set: { settingsStore.settings.saturation = $0 }
                        ),
                        range: 0.0...2.0
                    )

                    Toggle("Black & White", isOn: $settingsStore.settings.blackAndWhite)
                        .tint(.pink)

                    HStack(spacing: 8) {
                        Text("Blob Color")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(action: cycleBlobColorMode) {
                            Text(settingsStore.settings.blobColorMode.displayName)
                                .font(.caption.bold())
                                .padding(8)
                                .background(settingsStore.settings.blobColorMode == .white ? Color.white : settingsStore.settings.blobColorMode == .red ? Color.red : Color.purple)
                                .foregroundColor(settingsStore.settings.blobColorMode == .white ? .black : .white)
                                .cornerRadius(8)
                        }
                    }
                }
            }

            HStack {  // HStack for expand toggle
                Spacer()  // Spacer
                Button(action: { isExpanded.toggle() }) {  // Button to toggle expand
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")  // Image
                        .foregroundStyle(.secondary)  // Style
                }
                Spacer()  // Spacer
            }
        }
        .padding(16)  // Padding
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))  // Background
        .onChange(of: viewModel.cameraPosition) { newPosition in
            if newPosition == .front { selectedCameraType = .wide }
        }
    }

    private func cycleBlobColorMode() {
        switch settingsStore.settings.blobColorMode {
        case .white:
            settingsStore.settings.blobColorMode = .rainbow
        case .rainbow:
            settingsStore.settings.blobColorMode = .red
        case .red:
            settingsStore.settings.blobColorMode = .white
        }
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {  // Function for slider row
        VStack(alignment: .leading, spacing: 4) {  // VStack
            HStack {  // HStack for title and value
                Text(title)  // Title
                    .foregroundStyle(.secondary)  // Style
                Spacer()  // Spacer
                Text("\(Int(value.wrappedValue.rounded()))")  // Value text
                    .font(.caption.monospaced())  // Font
            }
            Slider(value: value, in: range)  // Slider
        }
    }
}
