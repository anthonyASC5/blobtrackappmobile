import CoreMedia
import CoreVideo

enum FrameCapture {
    static func makeFrameData(from sampleBuffer: CMSampleBuffer) -> FrameData? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        return FrameData(
            pixelBuffer: pixelBuffer,
            timestamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        )
    }

    static func makeFrameData(from pixelBuffer: CVPixelBuffer, timestamp: CMTime = .zero) -> FrameData {
        FrameData(pixelBuffer: pixelBuffer, timestamp: timestamp)
    }
}
