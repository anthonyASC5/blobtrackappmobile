import CoreGraphics
import Foundation

enum MathUtils {
    static func clamp<T: Comparable>(_ value: T, lower: T, upper: T) -> T {
        min(max(value, lower), upper)
    }

    static func distance(from lhs: CGPoint, to rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return sqrt(dx * dx + dy * dy)
    }

    static func fitRect(source: CGSize, into container: CGSize) -> CGRect {
        guard source.width > 0, source.height > 0, container.width > 0, container.height > 0 else {
            return CGRect(origin: .zero, size: container)
        }

        let widthRatio = container.width / source.width
        let heightRatio = container.height / source.height
        let scale = min(widthRatio, heightRatio)
        let size = CGSize(width: source.width * scale, height: source.height * scale)

        return CGRect(
            x: (container.width - size.width) * 0.5,
            y: (container.height - size.height) * 0.5,
            width: size.width,
            height: size.height
        )
    }

    static func formattedTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let totalSeconds = max(Int(seconds.rounded(.down)), 0)
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    static func absoluteVideoSize(naturalSize: CGSize, preferredTransform: CGAffineTransform) -> CGSize {
        let rect = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform).standardized
        return CGSize(width: abs(rect.width), height: abs(rect.height))
    }
}
