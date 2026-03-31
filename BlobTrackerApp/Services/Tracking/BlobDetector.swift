import CoreGraphics
import Foundation

struct DetectedBlob {
    let centroid: CGPoint
    let area: Int
    let boundingBox: CGRect
}

final class BlobDetector {
    func detect(
        in frame: FrameData,
        settings: TrackingSettings,
        previousGrayscale: GrayscaleImage?
    ) -> (detections: [DetectedBlob], grayscale: GrayscaleImage) {
        var grayscale = ImageProcessing.grayscale(
            from: frame.pixelBuffer,
            downsampleFactor: settings.downsampleFactor
        )

        grayscale = ImageProcessing.boxBlur(grayscale, radius: settings.blurRadius)

        let binary: BinaryImage
        switch settings.detectionMode {
        case .binary:
            binary = ImageProcessing.threshold(
                grayscale,
                level: UInt8(clamping: Int(settings.threshold.rounded()))
            )

        case .motion:
            if let previousGrayscale {
                binary = MotionAnalyzer.motionMask(
                    current: grayscale,
                    previous: previousGrayscale,
                    threshold: UInt8(clamping: Int(settings.motionDifferenceThreshold.rounded()))
                )
            } else {
                binary = ImageProcessing.threshold(
                    grayscale,
                    level: UInt8(clamping: Int(settings.threshold.rounded()))
                )
            }

        case .edge:
            let edges = ImageProcessing.sobelEdges(from: grayscale)
            binary = ImageProcessing.threshold(
                edges,
                level: UInt8(clamping: Int(settings.edgeThreshold.rounded()))
            )
        }

        return (connectedComponents(in: binary, settings: settings), grayscale)
    }

    private func connectedComponents(in binary: BinaryImage, settings: TrackingSettings) -> [DetectedBlob] {
        guard binary.width > 0, binary.height > 0 else { return [] }
        var visited = [Bool](repeating: false, count: binary.width * binary.height)
        var blobs: [DetectedBlob] = []
        let minimumArea = max(settings.minimumBlobArea, 1)
        let maximumArea = max(settings.maximumBlobArea, minimumArea)

        for y in 0..<binary.height {
            for x in 0..<binary.width {
                let index = (y * binary.width) + x
                guard binary.pixels[index] == 1, !visited[index] else { continue }

                var queue: [Int] = [index]
                visited[index] = true
                var queueCursor = 0
                var area = 0
                var sumX = 0
                var sumY = 0
                var minX = x
                var maxX = x
                var minY = y
                var maxY = y

                while queueCursor < queue.count {
                    let current = queue[queueCursor]
                    queueCursor += 1

                    let currentX = current % binary.width
                    let currentY = current / binary.width

                    area += 1
                    sumX += currentX
                    sumY += currentY
                    minX = min(minX, currentX)
                    maxX = max(maxX, currentX)
                    minY = min(minY, currentY)
                    maxY = max(maxY, currentY)

                    let neighbors = [
                        (currentX - 1, currentY),
                        (currentX + 1, currentY),
                        (currentX, currentY - 1),
                        (currentX, currentY + 1)
                    ]

                    for (neighborX, neighborY) in neighbors {
                        guard
                            neighborX >= 0,
                            neighborX < binary.width,
                            neighborY >= 0,
                            neighborY < binary.height
                        else {
                            continue
                        }

                        let neighborIndex = (neighborY * binary.width) + neighborX
                        guard binary.pixels[neighborIndex] == 1, !visited[neighborIndex] else { continue }
                        visited[neighborIndex] = true
                        queue.append(neighborIndex)
                    }
                }

                guard area >= minimumArea, area <= maximumArea else { continue }

                let centroid = CGPoint(
                    x: (CGFloat(sumX) / CGFloat(area) + 0.5) / CGFloat(binary.width),
                    y: (CGFloat(sumY) / CGFloat(area) + 0.5) / CGFloat(binary.height)
                )

                let box = CGRect(
                    x: CGFloat(minX) / CGFloat(binary.width),
                    y: CGFloat(minY) / CGFloat(binary.height),
                    width: CGFloat((maxX - minX) + 1) / CGFloat(binary.width),
                    height: CGFloat((maxY - minY) + 1) / CGFloat(binary.height)
                )

                blobs.append(DetectedBlob(centroid: centroid, area: area, boundingBox: box))
            }
        }

        return blobs.sorted { $0.area > $1.area }
    }
}
