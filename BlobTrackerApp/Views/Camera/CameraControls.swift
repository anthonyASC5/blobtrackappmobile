import SwiftUI

struct CameraControls: View {
    @ObservedObject var viewModel: CameraViewModel
    @ObservedObject var settingsStore: TrackingSettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Button(action: viewModel.toggleTracking) {
                    Label(
                        viewModel.isTrackingEnabled ? "Tracking On" : "Tracking Off",
                        systemImage: viewModel.isTrackingEnabled ? "dot.scope" : "pause.circle"
                    )
                    .font(.headline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
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

            VStack(alignment: .leading, spacing: 8) {
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
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value.wrappedValue.rounded()))")
                    .font(.caption.monospaced())
            }
            Slider(value: value, in: range)
        }
    }
}
