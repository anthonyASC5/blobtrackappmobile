import CoreGraphics
import CoreMedia
import Foundation

enum Constants {
    static let appName = "BlobTracker"
    static let processingQueueLabel = "com.blobtracker.processing"
    static let cameraQueueLabel = "com.blobtracker.camera"
    static let videoFrameQueueLabel = "com.blobtracker.video"
    static let exportQueueLabel = "com.blobtracker.export"
    static let analysisInterval = CMTime(value: 1, timescale: 15)
    static let previewPlaceholderSize = CGSize(width: 1920, height: 1080)
    static let overlayLineWidth: CGFloat = 2
    static let minimumBlobRenderSize: CGFloat = 10
}
