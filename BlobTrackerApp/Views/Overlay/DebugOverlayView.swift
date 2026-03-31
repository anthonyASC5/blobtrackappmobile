import SwiftUI

struct DebugOverlayView: View {
    let mode: DetectionMode
    let framesPerSecond: Double
    let processingMilliseconds: Double
    let blobCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            debugRow(title: "Mode", value: mode.displayName)
            debugRow(title: "FPS", value: String(format: "%.1f", framesPerSecond))
            debugRow(title: "Process", value: String(format: "%.1f ms", processingMilliseconds))
            debugRow(title: "Blobs", value: "\(blobCount)")
        }
        .font(.caption.monospaced())
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private func debugRow(title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .fontWeight(.semibold)
        }
    }
}
