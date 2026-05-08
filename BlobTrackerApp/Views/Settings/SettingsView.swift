import SwiftUI  // Import for SwiftUI

struct SettingsView: View {  // View for settings
    @ObservedObject var settingsStore: TrackingSettingsStore  // Observed settings store

    var body: some View {  // Body
        Form {  // Form for settings
            Section("Presets") {  // Section for presets
                ForEach(settingsStore.presets) { preset in  // For each preset
                    Button {  // Button to apply preset
                        settingsStore.apply(preset)  // Apply
                    } label: {  // Label
                        HStack {  // HStack
                            Text(preset.name)  // Name
                            Spacer()  // Spacer
                            if preset.settings == settingsStore.settings {  // If current
                                Image(systemName: "checkmark.circle.fill")  // Checkmark
                                    .foregroundStyle(Color.accentColor)  // Style
                            }
                        }
                    }
                }

                Button("Reset to Default", role: .destructive, action: settingsStore.reset)  // Reset button
            }

            Section("Detection") {  // Section for detection
                Picker("Mode", selection: $settingsStore.settings.detectionMode) {  // Picker for mode
                    ForEach(DetectionMode.allCases) { mode in  // For each mode
                        Text(mode.displayName).tag(mode)  // Text
                    }
                }

                slider(title: "Threshold", value: $settingsStore.settings.threshold, range: 0...255)  // Slider
                slider(title: "Motion Threshold", value: $settingsStore.settings.motionDifferenceThreshold, range: 0...255)  // Slider
                slider(title: "Edge Threshold", value: $settingsStore.settings.edgeThreshold, range: 0...255)  // Slider

                Stepper(value: $settingsStore.settings.blurRadius, in: 0...4) {  // Stepper
                    LabeledContent("Blur Radius", value: "\(settingsStore.settings.blurRadius)")  // Content
                }
                Stepper(value: $settingsStore.settings.downsampleFactor, in: 1...8) {  // Stepper
                    LabeledContent("Downsample", value: "\(settingsStore.settings.downsampleFactor)x")  // Content
                }
            }

            Section("Blob Filtering") {  // Section for filtering
                Stepper(value: $settingsStore.settings.minimumBlobArea, in: 1...2000) {  // Stepper
                    LabeledContent("Min Area", value: "\(settingsStore.settings.minimumBlobArea)")  // Content
                }
                Stepper(value: $settingsStore.settings.maximumBlobArea, in: 100...100_000, step: 100) {  // Stepper
                    LabeledContent("Max Area", value: "\(settingsStore.settings.maximumBlobArea)")  // Content
                }
                slider(title: "Match Distance", value: $settingsStore.settings.maxTrackingDistance, range: 0.02...0.35)  // Slider
                Stepper(value: $settingsStore.settings.trailLength, in: 1...30) {  // Stepper
                    LabeledContent("Trail Length", value: "\(settingsStore.settings.trailLength)")  // Content
                }
            }

            Section("Overlay") {  // Section for overlay
                Toggle("Show Bounding Boxes", isOn: $settingsStore.settings.showBoundingBoxes)  // Toggle
                Toggle("Show Trails", isOn: $settingsStore.settings.showTrails)  // Toggle
                Toggle("Show Blob Circles", isOn: $settingsStore.settings.showBlobCircles)  // Toggle
                Toggle("Show Debug Overlay", isOn: $settingsStore.settings.showDebugInfo)  // Toggle
            }

            Section("About") {  // Section for about
                NavigationLink(destination: AboutView()) {  // Link to about view
                    Text("About the App")  // Text
                }
            }
        }
        .navigationTitle("Tracking Settings")  // Title
        .navigationBarTitleDisplayMode(.inline)  // Mode
        .onChange(of: settingsStore.settings.detectionMode) { _, newMode in
            if newMode == .motion {
                settingsStore.settings.applyMotionDefaults()
            }
        }
    }

}

extension SettingsView {
    private func slider(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {  // Function for slider
        VStack(alignment: .leading, spacing: 6) {  // VStack
            HStack {  // HStack
                Text(title)  // Title
                Spacer()  // Spacer
                Text(String(format: "%.2f", value.wrappedValue))  // Value
                    .foregroundStyle(.secondary)  // Style
                    .font(.caption.monospaced())  // Font
            }
            Slider(value: value, in: range)  // Slider
        }
    }
}
