import CoreGraphics
import UIKit

enum OverlayRenderer {
    static func contentRect(containerSize: CGSize, sourceSize: CGSize) -> CGRect {
        MathUtils.fitRect(source: sourceSize, into: containerSize)
    }

    static func point(for normalizedPoint: CGPoint, in contentRect: CGRect) -> CGPoint {
        CGPoint(
            x: contentRect.minX + (normalizedPoint.x * contentRect.width),
            y: contentRect.minY + (normalizedPoint.y * contentRect.height)
        )
    }

    static func rect(for normalizedRect: CGRect, in contentRect: CGRect) -> CGRect {
        CGRect(
            x: contentRect.minX + (normalizedRect.minX * contentRect.width),
            y: contentRect.minY + (normalizedRect.minY * contentRect.height),
            width: normalizedRect.width * contentRect.width,
            height: normalizedRect.height * contentRect.height
        )
    }

    static func renderAnnotatedImage(
        from pixelBuffer: CVPixelBuffer,
        blobs: [Blob],
        settings: TrackingSettings
    ) -> CGImage? {
        guard let baseImage = pixelBuffer.cgImage() else { return nil }

        let imageSize = CGSize(width: baseImage.width, height: baseImage.height)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let image = renderer.image { context in
            UIImage(cgImage: baseImage).draw(in: CGRect(origin: .zero, size: imageSize))
            draw(blobs: blobs, in: context.cgContext, contentRect: CGRect(origin: .zero, size: imageSize), settings: settings)
        }

        return image.cgImage
    }

    static func draw(
        blobs: [Blob],
        in context: CGContext,
        contentRect: CGRect,
        settings: TrackingSettings
    ) {
        context.saveGState()
        context.setLineWidth(Constants.overlayLineWidth)

        for blob in blobs {
            let color = color(for: blob.id, mode: settings.blobColorMode)
            context.setStrokeColor(color.cgColor)
            context.setFillColor(color.withAlphaComponent(0.18).cgColor)

            if settings.showTrails, blob.trail.count > 1 {
                let trailPoints = blob.trail.map { point(for: $0, in: contentRect) }
                let trailPath = UIBezierPath()
                trailPath.move(to: trailPoints[0])
                trailPoints.dropFirst().forEach { trailPath.addLine(to: $0) }
                context.setLineWidth(Constants.overlayLineWidth * 0.8)
                context.addPath(trailPath.cgPath)
                context.strokePath()
                context.setLineWidth(Constants.overlayLineWidth)
            }

            let box = rect(for: blob.boundingBox, in: contentRect)
            let center = point(for: blob.position, in: contentRect)
            let radius = max(max(box.width, box.height) * 0.35, Constants.minimumBlobRenderSize)

            context.fillEllipse(in: CGRect(x: center.x - radius * 0.5, y: center.y - radius * 0.5, width: radius, height: radius))

            if settings.showBoundingBoxes {
                context.stroke(box)
            }

            let label = "\(blob.id.uuidString.prefix(4))"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: color
            ]
            label.draw(at: CGPoint(x: box.minX + 4, y: max(box.minY - 16, contentRect.minY + 4)), withAttributes: attributes)
        }

        context.restoreGState()
    }

    static func color(for id: UUID, mode: BlobColorMode = .rainbow) -> UIColor {
        switch mode {
        case .white:
            return .white
        case .rainbow:
            let hash = abs(id.uuidString.hashValue)
            let hue = CGFloat(hash % 360) / 360.0
            return UIColor(hue: hue, saturation: 0.85, brightness: 1.0, alpha: 1.0)
        case .red:
            return .red
        }
    }
}
