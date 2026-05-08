import SwiftUI

struct BlobColorModeButton: View {
    let mode: BlobColorMode
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(foregroundColor)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .background {
                    Capsule(style: .continuous)
                        .fill(mode.fillStyle)
                }
                .shadow(color: Color.black.opacity(0.10), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch mode {
        case .white:
            .black
        case .rainbow, .red, .neonBlue:
            .white
        }
    }
}

private extension BlobColorMode {
    var fillStyle: AnyShapeStyle {
        switch self {
        case .white:
            return AnyShapeStyle(Color.white)
        case .red:
            return AnyShapeStyle(Color.red)
        case .rainbow:
            return AnyShapeStyle(
                AngularGradient(
                    colors: [
                        .pink,
                        .orange,
                        .yellow,
                        .mint,
                        .cyan,
                        .blue,
                        .purple,
                        .pink
                    ],
                    center: .center
                )
            )
        case .neonBlue:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.75, blue: 1.0),
                        Color(red: 0.0, green: 0.35, blue: 0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}
