import AVFoundation
import Foundation

struct VideoSource {
    let url: URL
    let asset: AVURLAsset
}

enum VideoLoaderError: LocalizedError {
    case failedToPrepareVideo

    var errorDescription: String? {
        switch self {
        case .failedToPrepareVideo:
            "The selected video could not be opened."
        }
    }
}

final class VideoLoader {
    func prepareVideo(from sourceURL: URL) async throws -> VideoSource {
        let cacheDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("BlobTracker", isDirectory: true)
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        let destinationURL = cacheDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw VideoLoaderError.failedToPrepareVideo
        }

        let asset = AVURLAsset(url: destinationURL)
        return VideoSource(url: destinationURL, asset: asset)
    }
}
