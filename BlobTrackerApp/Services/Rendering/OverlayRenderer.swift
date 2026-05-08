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
        settings: TrackingSettings,
        depthPixelBuffer: CVPixelBuffer? = nil
    ) -> CGImage? {
        let baseImage: CGImage?

        if settings.visualEffectMode == .lidarScan,
           let depthPixelBuffer,
           let depthImage = DepthMapRenderer.renderDepthScan(from: depthPixelBuffer, maxDepthMeters: 4.5, scaleFactor: 1.0) {
            baseImage = depthImage
        } else {
            baseImage = pixelBuffer.cgImage()
        }

        guard let baseImage else { return nil }

        let imageSize = CGSize(width: baseImage.width, height: baseImage.height)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let image = renderer.image { context in
            UIImage(cgImage: baseImage).draw(in: CGRect(origin: .zero, size: imageSize))
            draw(blobs: blobs, in: context.cgContext, contentRect: CGRect(origin: .zero, size: imageSize), settings: settings)
        }
        guard let cgImage = image.cgImage else {
            return nil
        }

        if settings.visualEffectMode == .lidarScan {
            return cgImage
        }

        return ImageProcessing.applyEditorAdjustments(to: cgImage, settings: settings) ?? cgImage
    }

    static func draw(
        blobs: [Blob],
        in context: CGContext,
        contentRect: CGRect,
        settings: TrackingSettings
    ) {
        context.saveGState()
        context.setLineWidth(Constants.overlayLineWidth)
        // The glow pass draws wider, softer strokes before the final crisp outline.
        let glowWidth = CGFloat(8 + (18 * (settings.glow / 100.0)))

        if settings.showTrails, blobs.count > 1 {
            context.setLineWidth(Constants.overlayLineWidth * 0.9)
            for index in 0..<(blobs.count - 1) {
                let startBlob = blobs[index]
                let endBlob = blobs[index + 1]
                let start = point(for: startBlob.position, in: contentRect)
                let end = point(for: endBlob.position, in: contentRect)
                let segmentColor = color(for: startBlob.id, mode: settings.blobColorMode, effectMode: settings.visualEffectMode)
                drawGlowStroke(
                    context: context,
                    path: CGPath.makeLine(from: start, to: end),
                    color: segmentColor,
                    glowWidth: glowWidth,
                    baseWidth: Constants.overlayLineWidth * 0.9,
                    baseOpacity: 0.35,
                    glowStrength: settings.glow
                )
            }
            context.setLineWidth(Constants.overlayLineWidth)
        }

        for blob in blobs {
            let color = color(for: blob.id, mode: settings.blobColorMode, effectMode: settings.visualEffectMode)
            context.setFillColor(color.withAlphaComponent(0.18).cgColor)

            if settings.showTrails, blob.trail.count > 1 {
                let trailPoints = blob.trail.map { point(for: $0, in: contentRect) }
                let trailPath = UIBezierPath()
                trailPath.move(to: trailPoints[0])
                trailPoints.dropFirst().forEach { trailPath.addLine(to: $0) }
                drawGlowStroke(
                    context: context,
                    path: trailPath.cgPath,
                    color: color,
                    glowWidth: glowWidth,
                    baseWidth: Constants.overlayLineWidth * 0.8,
                    baseOpacity: 0.85,
                    glowStrength: settings.glow
                )
            }

            let box = rect(for: blob.boundingBox, in: contentRect)
            let center = point(for: blob.position, in: contentRect)
            let radius = max(max(box.width, box.height) * 0.35, Constants.minimumBlobRenderSize)

            if settings.showBlobCircles {
                context.fillEllipse(in: CGRect(x: center.x - radius * 0.5, y: center.y - radius * 0.5, width: radius, height: radius))
            }

            if settings.showBoundingBoxes {
                drawGlowStroke(
                    context: context,
                    path: CGPath(rect: box, transform: nil),
                    color: color,
                    glowWidth: glowWidth,
                    baseWidth: Constants.overlayLineWidth,
                    baseOpacity: 1.0,
                    glowStrength: settings.glow
                )
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

    private static func drawGlowStroke(
        context: CGContext,
        path: CGPath,
        color: UIColor,
        glowWidth: CGFloat,
        baseWidth: CGFloat,
        baseOpacity: Double,
        glowStrength: Double
    ) {
        let normalizedGlow = max(0, min(glowStrength, 100)) / 100.0
        let glowPasses = max(1, Int((glowStrength / 25).rounded(.up)))

        if normalizedGlow > 0 {
            for pass in stride(from: glowPasses, through: 1, by: -1) {
                let progress = CGFloat(Double(pass) / Double(glowPasses))
                context.setStrokeColor(color.withAlphaComponent(CGFloat(baseOpacity) * 0.08 * progress).cgColor)
                context.setLineWidth(baseWidth + (glowWidth * progress))
                context.addPath(path)
                context.strokePath()
            }
        }

        context.setStrokeColor(color.withAlphaComponent(CGFloat(baseOpacity)).cgColor)
        context.setLineWidth(baseWidth)
        context.addPath(path)
        context.strokePath()
    }

    static func color(for id: UUID, mode: BlobColorMode = .rainbow, effectMode: VisualEffectMode = .off) -> UIColor {
        switch effectMode {
        case .nightVision:
            return UIColor(red: 0.0, green: 1.0, blue: 0.2, alpha: 1.0)
        case .lidarScan:
            return UIColor(white: 1.0, alpha: 0.95)
        case .off:
            break
        }

        switch mode {
        case .white:
            return .white
        case .rainbow:
            let hash = abs(id.uuidString.hashValue)
            let hue = CGFloat(hash % 360) / 360.0
            return UIColor(hue: hue, saturation: 0.85, brightness: 1.0, alpha: 1.0)
        case .red:
            return .red
        case .neonBlue:
            return UIColor(red: 0.0, green: 0.82, blue: 1.0, alpha: 1.0)
        }
    }
}

private extension CGPath {
    static func makeLine(from start: CGPoint, to end: CGPoint) -> CGPath {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}
