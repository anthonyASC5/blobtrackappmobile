import Photos
import UIKit

enum FrameWriterError: LocalizedError {
    case renderFailed
    case photoLibraryDenied
    case imageDataFailed

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            "BlobTracker could not render the annotated frame."
        case .photoLibraryDenied:
            "Photo library access was denied. Enable add-only access in Settings to save frames."
        case .imageDataFailed:
            "BlobTracker could not encode the exported frame."
        }
    }
}

final class FrameWriter {
    func saveAnnotatedFrame(
        frame: FrameData,
        blobs: [Blob],
        settings: TrackingSettings
    ) async throws {
        guard let cgImage = OverlayRenderer.renderAnnotatedImage(from: frame.pixelBuffer, blobs: blobs, settings: settings) else {
            throw FrameWriterError.renderFailed
        }

        guard let imageData = UIImage(cgImage: cgImage).pngData() else {
            throw FrameWriterError.imageDataFailed
        }

        try await requestAddPermission()
        try await saveImageData(imageData)
    }

    private func requestAddPermission() async throws {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if currentStatus == .authorized || currentStatus == .limited {
            return
        }

        let status = await withCheckedContinuation { (continuation: CheckedContinuation<PHAuthorizationStatus, Never>) in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
        guard status == .authorized || status == .limited else {
            throw FrameWriterError.photoLibraryDenied
        }
    }

    private func saveImageData(_ data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                request.addResource(with: .photo, data: data, options: options)
            }, completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: FrameWriterError.imageDataFailed)
                }
            })
        }
    }
}
