import CoreGraphics
import CoreVideo
import Foundation

enum DepthMapRenderer {
    static func renderDepthScan(
        from depthPixelBuffer: CVPixelBuffer,
        maxDepthMeters: Float = 4.5,
        scaleFactor: CGFloat = 1.0
    ) -> CGImage? {
        let sourceWidth = CVPixelBufferGetWidth(depthPixelBuffer)
        let sourceHeight = CVPixelBufferGetHeight(depthPixelBuffer)
        let width = max(Int(CGFloat(sourceWidth) * scaleFactor), 1)
        let height = max(Int(CGFloat(sourceHeight) * scaleFactor), 1)

        var grayscale = [UInt8](repeating: 0, count: width * height)

        CVPixelBufferLockBaseAddress(depthPixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(depthPixelBuffer) else {
            return nil
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthPixelBuffer)

        for y in 0..<height {
            let sourceY = min(Int(CGFloat(y) / scaleFactor), sourceHeight - 1)
            let row = baseAddress.advanced(by: sourceY * bytesPerRow).assumingMemoryBound(to: Float16.self)
            for x in 0..<width {
                let sourceX = min(Int(CGFloat(x) / scaleFactor), sourceWidth - 1)
                let depth = Float(row[sourceX])
                grayscale[(y * width) + x] = normalizedDepthValue(depth, maxDepthMeters: maxDepthMeters)
            }
        }

        guard let provider = CGDataProvider(data: Data(grayscale) as CFData) else {
            return nil
        }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }

    private static func normalizedDepthValue(_ depth: Float, maxDepthMeters: Float) -> UInt8 {
        guard depth.isFinite, depth > 0 else { return 255 }
        let clamped = min(max(depth, 0), maxDepthMeters)
        let normalized = clamped / maxDepthMeters
        let contrastBoost = pow(normalized, 0.72)
        let lifted = UInt8(max(0, min(255, Int(contrastBoost * 255))))
        return lifted
    }
}
