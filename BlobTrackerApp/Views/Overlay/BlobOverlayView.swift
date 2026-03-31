import SwiftUI

struct BlobOverlayView: View {
    let blobs: [Blob]
    let sourceSize: CGSize
    let settings: TrackingSettings

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let contentRect = OverlayRenderer.contentRect(containerSize: size, sourceSize: sourceSize)

                for blob in blobs {
                    let color = Color(uiColor: OverlayRenderer.color(for: blob.id))

                    if settings.showTrails, blob.trail.count > 1 {
                        var path = Path()
                        let points = blob.trail.map { OverlayRenderer.point(for: $0, in: contentRect) }
                        path.move(to: points[0])
                        points.dropFirst().forEach { path.addLine(to: $0) }
                        context.stroke(path, with: .color(color.opacity(0.85)), lineWidth: Constants.overlayLineWidth)
                    }

                    let rect = OverlayRenderer.rect(for: blob.boundingBox, in: contentRect)
                    let center = OverlayRenderer.point(for: blob.position, in: contentRect)
                    let radius = max(max(rect.width, rect.height) * 0.35, Constants.minimumBlobRenderSize)

                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: center.x - radius * 0.5,
                            y: center.y - radius * 0.5,
                            width: radius,
                            height: radius
                        )),
                        with: .color(color.opacity(0.18))
                    )

                    if settings.showBoundingBoxes {
                        context.stroke(Path(rect), with: .color(color), lineWidth: Constants.overlayLineWidth)
                    }

                    let label = Text(String(blob.id.uuidString.prefix(4)))
                        .font(.caption2.monospaced())
                        .foregroundStyle(color)
                    context.draw(
                        label,
                        at: CGPoint(x: rect.minX + 6, y: max(rect.minY - 14, contentRect.minY + 6)),
                        anchor: .topLeading
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}
