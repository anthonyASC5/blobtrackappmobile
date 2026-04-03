import SwiftUI  // Import for SwiftUI views

struct BlobOverlayView: View {  // View for overlaying blob visuals on camera
    let blobs: [Blob]  // Array of blobs to display
    let sourceSize: CGSize  // Size of source frame
    let settings: TrackingSettings  // Tracking settings

    var body: some View {  // Body of the view
        GeometryReader { geometry in  // Geometry reader for size
            Canvas { context, size in  // Canvas for drawing
                let contentRect = OverlayRenderer.contentRect(containerSize: size, sourceSize: sourceSize)  // Content rect

                for blob in blobs {  // Loop through blobs
                    let color = Color(uiColor: OverlayRenderer.color(for: blob.id))  // Get color for blob

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

                    context.fill(  // Fill ellipse
                        Path(ellipseIn: CGRect(
                            x: center.x - radius * 0.5,
                            y: center.y - radius * 0.5,
                            width: radius,
                            height: radius
                        )),
                        with: .color(color.opacity(0.18))
                    )

                    if settings.showBoundingBoxes {  // If show boxes
                        context.stroke(Path(rect), with: .color(color), lineWidth: Constants.overlayLineWidth)  // Stroke rect
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
}
