import SwiftUI  // Import for SwiftUI

struct CameraControls: View {  // View for camera controls
    @ObservedObject var viewModel: CameraViewModel  // Observed view model
    @ObservedObject var settingsStore: TrackingSettingsStore  // Observed settings
    @State private var isExpanded = true  // State for expanded HUD
    @State private var selectedCameraType: CameraType = .wide  // State for camera type

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

                    Picker("Mode", selection: $settingsStore.settings.detectionMode) {  // Picker for mode
                        ForEach(DetectionMode.allCases) { mode in  // For each mode
                            Text(mode.displayName).tag(mode)  // Text with tag
                        }
                    }
                    .pickerStyle(.segmented)  // Segmented style
                }

                HStack(spacing: 12) {  // HStack for camera controls
                    Button(action: viewModel.flipCamera) {  // Button to flip camera
                        Label("Flip Camera", systemImage: "camera.rotate")  // Label
                    }
                    .buttonStyle(.bordered)  // Style

                    Picker("Lens", selection: $selectedCameraType) {  // Picker for lens
                        Text("Wide").tag(CameraType.wide)  // Wide option
                        Text("Ultra Wide").tag(CameraType.ultraWide)  // Ultra wide option
                    }
                    .pickerStyle(.segmented)  // Segmented
                    .onChange(of: selectedCameraType) { viewModel.setCameraType($0) }  // On change
                }

                VStack(alignment: .leading, spacing: 8) {  // VStack for sliders
                    sliderRow(  // Slider row for threshold
                        title: "Threshold",
                        value: Binding(  // Binding for value
                            get: { settingsStore.settings.threshold },
                            set: { settingsStore.settings.threshold = $0 }
                        ),
                        range: 0...255  // Range
                    )

                    sliderRow(  // Slider for min area
                        title: "Min Area",
                        value: Binding(  // Binding
                            get: { Double(settingsStore.settings.minimumBlobArea) },
                            set: { settingsStore.settings.minimumBlobArea = Int($0.rounded()) }
                        ),
                        range: 1...400  // Range
                    )
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
