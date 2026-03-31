import CoreGraphics
import CoreMedia
import CoreVideo

struct FrameData {
    let pixelBuffer: CVPixelBuffer
    let timestamp: CMTime
    let size: CGSize

    init(pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        self.pixelBuffer = pixelBuffer
        self.timestamp = timestamp
        size = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
    }
}
