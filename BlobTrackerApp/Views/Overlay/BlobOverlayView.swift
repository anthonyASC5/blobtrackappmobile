import SwiftUI  // Import for SwiftUI views

struct BlobOverlayView: View {  // View for overlaying blob visuals on camera
    let blobs: [Blob]  // Array of blobs to display
    let sourceSize: CGSize  // Size of source frame
    let settings: TrackingSettings  // Tracking settings

    var body: some View {  // Body of the view
        GeometryReader { _ in  // Geometry reader for size
            Canvas { context, size in  // Canvas for drawing
                let contentRect = OverlayRenderer.contentRect(containerSize: size, sourceSize: sourceSize)  // Content rect
                let glowStrength = settings.glow / 100.0
                let glowWidth = CGFloat(8 + (18 * glowStrength))

                if settings.showTrails, blobs.count > 1 {
                    for index in 0..<(blobs.count - 1) {
                        let startBlob = blobs[index]
                        let endBlob = blobs[index + 1]
                        let start = OverlayRenderer.point(for: startBlob.position, in: contentRect)
                        let end = OverlayRenderer.point(for: endBlob.position, in: contentRect)
                        let segmentColor = Color(uiColor: OverlayRenderer.color(for: startBlob.id, mode: settings.blobColorMode, effectMode: settings.visualEffectMode))
                        var connectorPath = Path()
                        connectorPath.move(to: start)
                        connectorPath.addLine(to: end)
                        drawGlowStroke(
                            context: context,
                            path: connectorPath,
                            color: segmentColor,
                            glowWidth: glowWidth,
                            baseWidth: Constants.overlayLineWidth * 0.9,
                            baseOpacity: 0.35
                        )
                    }
                }

                for blob in blobs {  // Loop through blobs
                    let color = Color(uiColor: OverlayRenderer.color(for: blob.id, mode: settings.blobColorMode, effectMode: settings.visualEffectMode))  // Get color for blob

                    if settings.showTrails, blob.trail.count > 1 {  // If show trails and trail exists
                        var path = Path()  // Create path
                        let points = blob.trail.map { OverlayRenderer.point(for: $0, in: contentRect) }  // Map points
                        path.move(to: points[0])  // Move to first point
                        points.dropFirst().forEach { path.addLine(to: $0) }  // Add lines
                        context.stroke(path, with: .color(color.opacity(0.85)), lineWidth: Constants.overlayLineWidth)  // Stroke path
                    }

                    let rect = OverlayRenderer.rect(for: blob.boundingBox, in: contentRect)  // Get rect
                    let center = OverlayRenderer.point(for: blob.position, in: contentRect)  // Get center
                    let radius = max(max(rect.width, rect.height) * 0.35, Constants.minimumBlobRenderSize)  // Calculate radius

                    // The soft fill keeps the blob visible even before the box stroke lands.
                    if settings.showBlobCircles {
                        context.fill(  // Fill ellipse
                            Path(ellipseIn: CGRect(
                                x: center.x - radius * 0.5,
                                y: center.y - radius * 0.5,
                                width: radius,
                                height: radius
                            )),
                            with: .color(color.opacity(0.18))
                        )
                    }

                    if settings.showBoundingBoxes {  // If show boxes
                        drawGlowStroke(
                            context: context,
                            path: Path(rect),
                            color: color,
                            glowWidth: glowWidth,
                            baseWidth: Constants.overlayLineWidth,
                            baseOpacity: 1.0
                        )
                    }

                    let label = Text(String(blob.id.uuidString.prefix(4)))  // Create label
                        .font(.caption2.monospaced())
                        .foregroundStyle(color)
                    context.draw(  // Draw label
                        label,
                        at: CGPoint(x: rect.minX + 6, y: max(rect.minY - 14, contentRect.minY + 6)),
                        anchor: .topLeading
                    )
                }
            }
        }
        .allowsHitTesting(false)  // Disable hit testing
    }

    private func drawGlowStroke(
        context: GraphicsContext,
        path: Path,
        color: Color,
        glowWidth: CGFloat,
        baseWidth: CGFloat,
        baseOpacity: Double
    ) {
        let glowPasses = max(1, Int((settings.glow / 25).rounded(.up)))

        if settings.glow > 0 {
            for pass in stride(from: glowPasses, through: 1, by: -1) {
                let progress = Double(pass) / Double(glowPasses)
                context.stroke(
                    path,
                    with: .color(color.opacity(baseOpacity * 0.10 * progress)),
                    lineWidth: baseWidth + (glowWidth * CGFloat(progress))
                )
            }
        }

        context.stroke(path, with: .color(color.opacity(baseOpacity)), lineWidth: baseWidth)
    }
}
