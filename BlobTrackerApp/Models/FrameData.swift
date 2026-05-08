import CoreGraphics
import CoreMedia
import CoreVideo

struct FrameData {
    let pixelBuffer: CVPixelBuffer
    let timestamp: CMTime
    let size: CGSize
    let depthPixelBuffer: CVPixelBuffer?

    init(pixelBuffer: CVPixelBuffer, timestamp: CMTime, depthPixelBuffer: CVPixelBuffer? = nil) {
        self.pixelBuffer = pixelBuffer
        self.timestamp = timestamp
        self.depthPixelBuffer = depthPixelBuffer
        size = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
    }
}
