import CoreVideo
import Foundation

struct GrayscaleImage {
    let width: Int
    let height: Int
    var pixels: [UInt8]
}

struct BinaryImage {
    let width: Int
    let height: Int
    var pixels: [UInt8]
}

enum ImageProcessing {
    static func grayscale(from pixelBuffer: CVPixelBuffer, downsampleFactor: Int) -> GrayscaleImage {
        let factor = max(downsampleFactor, 1)
        let sourceWidth = CVPixelBufferGetWidth(pixelBuffer)
        let sourceHeight = CVPixelBufferGetHeight(pixelBuffer)
        let width = max(sourceWidth / factor, 1)
        let height = max(sourceHeight / factor, 1)
        var pixels = [UInt8](repeating: 0, count: width * height)

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
        switch format {
        case kCVPixelFormatType_32BGRA:
            guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
                return GrayscaleImage(width: width, height: height, pixels: pixels)
            }

            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
            let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

            for y in 0..<height {
                let sourceY = min(y * factor, sourceHeight - 1)
                let row = buffer.advanced(by: sourceY * bytesPerRow)

                for x in 0..<width {
                    let sourceX = min(x * factor, sourceWidth - 1)
                    let offset = sourceX * 4
                    let blue = Double(row[offset])
                    let green = Double(row[offset + 1])
                    let red = Double(row[offset + 2])
                    let luma = (0.114 * blue) + (0.587 * green) + (0.299 * red)
                    pixels[(y * width) + x] = UInt8(MathUtils.clamp(Int(luma.rounded()), lower: 0, upper: 255))
                }
            }

        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            guard let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
                return GrayscaleImage(width: width, height: height, pixels: pixels)
            }

            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
            let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

            for y in 0..<height {
                let sourceY = min(y * factor, sourceHeight - 1)
                let row = buffer.advanced(by: sourceY * bytesPerRow)

                for x in 0..<width {
                    let sourceX = min(x * factor, sourceWidth - 1)
                    pixels[(y * width) + x] = row[sourceX]
                }
            }

        default:
            break
        }

        return GrayscaleImage(width: width, height: height, pixels: pixels)
    }

    static func boxBlur(_ image: GrayscaleImage, radius: Int) -> GrayscaleImage {
        guard radius > 0 else { return image }
        var output = [UInt8](repeating: 0, count: image.pixels.count)

        for y in 0..<image.height {
            for x in 0..<image.width {
                var sum = 0
                var count = 0

                for sampleY in max(0, y - radius)...min(image.height - 1, y + radius) {
                    for sampleX in max(0, x - radius)...min(image.width - 1, x + radius) {
                        sum += Int(image.pixels[(sampleY * image.width) + sampleX])
                        count += 1
                    }
                }

                output[(y * image.width) + x] = UInt8(sum / max(count, 1))
            }
        }

        return GrayscaleImage(width: image.width, height: image.height, pixels: output)
    }

    static func difference(current: GrayscaleImage, previous: GrayscaleImage) -> GrayscaleImage {
        guard current.width == previous.width, current.height == previous.height else {
            return current
        }

        let pixels = zip(current.pixels, previous.pixels).map { currentValue, previousValue in
            UInt8(abs(Int(currentValue) - Int(previousValue)))
        }

        return GrayscaleImage(width: current.width, height: current.height, pixels: pixels)
    }

    static func sobelEdges(from image: GrayscaleImage) -> GrayscaleImage {
        guard image.width > 2, image.height > 2 else { return image }
        var pixels = [UInt8](repeating: 0, count: image.pixels.count)

        let gx = [
            [-1, 0, 1],
            [-2, 0, 2],
            [-1, 0, 1]
        ]

        let gy = [
            [1, 2, 1],
            [0, 0, 0],
            [-1, -2, -1]
        ]

        for y in 1..<(image.height - 1) {
            for x in 1..<(image.width - 1) {
                var horizontal = 0
                var vertical = 0

                for kernelY in 0..<3 {
                    for kernelX in 0..<3 {
                        let sample = Int(image.pixels[((y + kernelY - 1) * image.width) + (x + kernelX - 1)])
                        horizontal += sample * gx[kernelY][kernelX]
                        vertical += sample * gy[kernelY][kernelX]
                    }
                }

                let magnitude = min(Int(sqrt(Double((horizontal * horizontal) + (vertical * vertical)))), 255)
                pixels[(y * image.width) + x] = UInt8(magnitude)
            }
        }

        return GrayscaleImage(width: image.width, height: image.height, pixels: pixels)
    }

    static func threshold(_ image: GrayscaleImage, level: UInt8) -> BinaryImage {
        let pixels = image.pixels.map { $0 >= level ? UInt8(1) : UInt8(0) }
        return BinaryImage(width: image.width, height: image.height, pixels: pixels)
    }
}
