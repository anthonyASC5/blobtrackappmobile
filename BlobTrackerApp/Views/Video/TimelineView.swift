import SwiftUI

struct VideoTimelineView: View {
    let currentTime: Double
    let duration: Double
    let onScrub: (Double) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { duration > 0 ? currentTime / duration : 0 },
                    set: onScrub
                ),
                in: 0...1
            )

            HStack {
                Text(MathUtils.formattedTime(currentTime))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(MathUtils.formattedTime(duration))
                    .foregroundStyle(.secondary)
            }
            .font(.caption.monospaced())
        }
    }
}
