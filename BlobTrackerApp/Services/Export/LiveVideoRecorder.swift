// THIS IS THE VIDEO IMPORT PAGE AND IT IS HIDDEN IN THE APP. THIS IS FOR THE NEXT VERSION AND WILL STAY PRIVATE UNTIL FULLY TESTED
import AVFoundation
import CoreGraphics
import CoreVideo
import Photos

enum LiveVideoRecorderError: LocalizedError {
    case notRecording
    case unableToCreateWriter
    case unableToCreateInput
    case unableToCreateBuffer
    case renderFailed
    case photoLibraryDenied
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .notRecording:
            "Recording has not started yet."
        case .unableToCreateWriter:
            "BlobTracker could not start the live recorder."
        case .unableToCreateInput:
            "BlobTracker could not prepare the recording stream."
        case .unableToCreateBuffer:
            "BlobTracker could not allocate a recording buffer."
        case .renderFailed:
            "BlobTracker could not render the live recording frame."
        case .photoLibraryDenied:
            "Photo library access was denied. Enable add-only access in Settings to save recordings."
        case .exportFailed:
            "BlobTracker failed to finish the live recording."
        }
    }
}

final class LiveVideoRecorder {
    private enum State {
        case idle
        case recording
        case finishing
    }

    private let queue = DispatchQueue(label: "\(Constants.exportQueueLabel).liveRecording")
    private var state: State = .idle
    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var outputURL: URL?
    private var didStartSession = false
    private var appendedFrameCount = 0

    func beginRecording(frame: FrameData, blobs: [Blob], settings: TrackingSettings) {
        queue.async { [weak self] in
            guard let self, self.state == .idle else { return }

            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")

            if FileManager.default.fileExists(atPath: outputURL.path) {
                try? FileManager.default.removeItem(at: outputURL)
            }

            guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mov) else {
                self.state = .idle
                return
            }

            let width = Int(frame.size.width.rounded())
            let height = Int(frame.size.height.rounded())

            let videoInput = AVAssetWriterInput(
                mediaType: .video,
                outputSettings: [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: width,
                    AVVideoHeightKey: height
                ]
            )
            videoInput.expectsMediaDataInRealTime = true

            guard writer.canAdd(videoInput) else {
                self.state = .idle
                return
            }
            writer.add(videoInput)

            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoInput,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                    kCVPixelBufferWidthKey as String: width,
                    kCVPixelBufferHeightKey as String: height
                ]
            )

            self.writer = writer
            self.videoInput = videoInput
            self.adaptor = adaptor
            self.outputURL = outputURL
            self.didStartSession = false
            self.appendedFrameCount = 0
            self.state = .recording

            self.appendLocked(frame: frame, blobs: blobs, settings: settings)
        }
    }

    func append(frame: FrameData, blobs: [Blob], settings: TrackingSettings) {
        queue.async { [weak self] in
            guard let self, self.state == .recording else { return }
            self.appendLocked(frame: frame, blobs: blobs, settings: settings)
        }
    }

    func finishAndSaveToPhotos() async throws {
        let outputURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: LiveVideoRecorderError.notRecording)
                    return
                }

                guard let writer = self.writer,
                      let videoInput = self.videoInput,
                      let outputURL = self.outputURL,
                      self.state == .recording || self.state == .finishing
                else {
                    continuation.resume(throwing: LiveVideoRecorderError.notRecording)
                    return
                }

                self.state = .finishing
                videoInput.markAsFinished()

                writer.finishWriting {
                    let resultURL = outputURL
                    self.writer = nil
                    self.videoInput = nil
                    self.adaptor = nil
                    self.outputURL = nil
                    self.didStartSession = false
                    self.appendedFrameCount = 0
                    self.state = .idle

                    if writer.status == .completed {
                        continuation.resume(returning: resultURL)
                    } else {
                        continuation.resume(throwing: writer.error ?? LiveVideoRecorderError.exportFailed)
                    }
                }
            }
        }

        try await requestAddPermission()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
            }, completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: LiveVideoRecorderError.exportFailed)
                }
            })
        }

        try? FileManager.default.removeItem(at: outputURL)
    }

    private func appendLocked(frame: FrameData, blobs: [Blob], settings: TrackingSettings) {
        guard
            let writer,
            let videoInput,
            let adaptor,
            let renderedImage = OverlayRenderer.renderAnnotatedImage(
                from: frame.pixelBuffer,
                blobs: blobs,
                settings: settings,
                depthPixelBuffer: frame.depthPixelBuffer
            )
        else {
            return
        }

        let effectMode = settings.visualEffectMode
        let frameStride = effectMode == .off ? 1 : 2
        guard appendedFrameCount % frameStride == 0 else {
            appendedFrameCount += 1
            return
        }
        appendedFrameCount += 1

        if !didStartSession {
            writer.startWriting()
            writer.startSession(atSourceTime: frame.timestamp)
            didStartSession = true
        }

        let scaleFactor: CGFloat = effectMode == .off ? 1.0 : 0.66
        guard let pixelBuffer = Self.makePixelBuffer(from: renderedImage, scaleFactor: scaleFactor) else {
            return
        }

        while !videoInput.isReadyForMoreMediaData {
            Thread.sleep(forTimeInterval: 0.0015)
        }

        _ = adaptor.append(pixelBuffer, withPresentationTime: frame.timestamp)
    }

    private static func makePixelBuffer(from cgImage: CGImage, scaleFactor: CGFloat = 1.0) -> CVPixelBuffer? {
        let width = max(Int(CGFloat(cgImage.width) * scaleFactor), 1)
        let height = max(Int(CGFloat(cgImage.height) * scaleFactor), 1)

        guard let pixelBuffer = CVPixelBuffer.make(width: width, height: height) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard
            let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
            let context = CGContext(
                data: baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
            )
        else {
            return nil
        }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixelBuffer
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
            throw LiveVideoRecorderError.photoLibraryDenied
        }
    }
}
