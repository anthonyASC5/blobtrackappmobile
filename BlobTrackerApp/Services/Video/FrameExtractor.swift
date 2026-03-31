@preconcurrency import AVFoundation
import CoreMedia
import Foundation

enum FrameExtractorError: LocalizedError {
    case unableToCreatePixelBuffer
    case noVideoTrack

    var errorDescription: String? {
        switch self {
        case .unableToCreatePixelBuffer:
            "BlobTracker could not convert the selected frame into a pixel buffer."
        case .noVideoTrack:
            "The imported file does not contain a video track."
        }
    }
}

final class FrameExtractor: @unchecked Sendable {
    private let asset: AVAsset
    private let generator: AVAssetImageGenerator
    private let queue = DispatchQueue(label: Constants.videoFrameQueueLabel)

    init(asset: AVAsset) {
        self.asset = asset
        generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
    }

    func extractFrame(at time: CMTime) async throws -> FrameData {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    var actualTime = CMTime.zero
                    let cgImage = try self.generator.copyCGImage(at: time, actualTime: &actualTime)

                    guard let pixelBuffer = CVPixelBuffer.make(from: cgImage) else {
                        continuation.resume(throwing: FrameExtractorError.unableToCreatePixelBuffer)
                        return
                    }

                    continuation.resume(returning: FrameData(pixelBuffer: pixelBuffer, timestamp: actualTime))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func videoSize() async throws -> CGSize {
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let track = tracks.first else {
            throw FrameExtractorError.noVideoTrack
        }

        let naturalSize = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)
        return MathUtils.absoluteVideoSize(naturalSize: naturalSize, preferredTransform: transform)
    }
}
