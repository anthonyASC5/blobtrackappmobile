import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: TrackingSettingsStore

    var body: some View {
        Form {
            Section("Presets") {
                ForEach(settingsStore.presets) { preset in
                    Button {
                        settingsStore.apply(preset)
                    } label: {
                        HStack {
                            Text(preset.name)
                            Spacer()
                            if preset.settings == settingsStore.settings {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }

                Button("Reset to Default", role: .destructive, action: settingsStore.reset)
            }

            Section("Detection") {
                Picker("Mode", selection: $settingsStore.settings.detectionMode) {
                    ForEach(DetectionMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                slider(title: "Threshold", value: $settingsStore.settings.threshold, range: 0...255)
                slider(title: "Motion Threshold", value: $settingsStore.settings.motionDifferenceThreshold, range: 0...255)
                slider(title: "Edge Threshold", value: $settingsStore.settings.edgeThreshold, range: 0...255)

                Stepper(value: $settingsStore.settings.blurRadius, in: 0...4) {
                    LabeledContent("Blur Radius", value: "\(settingsStore.settings.blurRadius)")
                }
                Stepper(value: $settingsStore.settings.downsampleFactor, in: 1...8) {
                    LabeledContent("Downsample", value: "\(settingsStore.settings.downsampleFactor)x")
                }
            }

            Section("Blob Filtering") {
                Stepper(value: $settingsStore.settings.minimumBlobArea, in: 1...2000) {
                    LabeledContent("Min Area", value: "\(settingsStore.settings.minimumBlobArea)")
                }
                Stepper(value: $settingsStore.settings.maximumBlobArea, in: 100...100_000, step: 100) {
                    LabeledContent("Max Area", value: "\(settingsStore.settings.maximumBlobArea)")
                }
                slider(title: "Match Distance", value: $settingsStore.settings.maxTrackingDistance, range: 0.02...0.35)
                Stepper(value: $settingsStore.settings.trailLength, in: 1...30) {
                    LabeledContent("Trail Length", value: "\(settingsStore.settings.trailLength)")
                }
            }

            Section("Overlay") {
                Toggle("Show Bounding Boxes", isOn: $settingsStore.settings.showBoundingBoxes)
                Toggle("Show Trails", isOn: $settingsStore.settings.showTrails)
                Toggle("Show Debug Overlay", isOn: $settingsStore.settings.showDebugInfo)
            }
        }
        .navigationTitle("Tracking Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func slider(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .foregroundStyle(.secondary)
                    .font(.caption.monospaced())
            }
            Slider(value: value, in: range)
        }
    }
}
