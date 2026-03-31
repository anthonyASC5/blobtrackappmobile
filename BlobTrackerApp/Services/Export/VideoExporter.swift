@preconcurrency import AVFoundation
import Photos
import UIKit

enum VideoExporterError: LocalizedError {
    case noVideoTrack
    case unableToCreateReader
    case unableToCreateWriter
    case unableToAppendFrame
    case exportFailed
    case photoLibraryDenied

    var errorDescription: String? {
        switch self {
        case .noVideoTrack:
            "The selected asset does not contain a video track."
        case .unableToCreateReader:
            "BlobTracker could not read the selected video."
        case .unableToCreateWriter:
            "BlobTracker could not create the exported video."
        case .unableToAppendFrame:
            "BlobTracker failed while writing an annotated frame."
        case .exportFailed:
            "BlobTracker failed to finish the video export."
        case .photoLibraryDenied:
            "Photo library access was denied. Enable add-only access in Settings to save videos."
        }
    }
}

final class VideoExporter: @unchecked Sendable {
    private let exportQueue = DispatchQueue(label: Constants.exportQueueLabel)

    func exportProcessedVideo(
        asset: AVAsset,
        settings: TrackingSettings,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw VideoExporterError.noVideoTrack
        }

        let audioTrack = try await asset.loadTracks(withMediaType: .audio).first
        let duration = try await asset.load(.duration)
        let durationSeconds = max(CMTimeGetSeconds(duration), 0.01)
        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)

        return try await withCheckedThrowingContinuation { continuation in
            exportQueue.async {
                do {
                    let outputURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension("mov")

                    if FileManager.default.fileExists(atPath: outputURL.path) {
                        try FileManager.default.removeItem(at: outputURL)
                    }

                    guard let reader = try? AVAssetReader(asset: asset) else {
                        throw VideoExporterError.unableToCreateReader
                    }

                    let videoOutput = AVAssetReaderTrackOutput(
                        track: videoTrack,
                        outputSettings: [
                            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                        ]
                    )
                    videoOutput.alwaysCopiesSampleData = false

                    guard reader.canAdd(videoOutput) else {
                        throw VideoExporterError.unableToCreateReader
                    }
                    reader.add(videoOutput)

                    var audioOutput: AVAssetReaderTrackOutput?
                    if let audioTrack {
                        let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
                        if reader.canAdd(output) {
                            reader.add(output)
                            audioOutput = output
                        }
                    }

                    guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mov) else {
                        throw VideoExporterError.unableToCreateWriter
                    }

                    let videoInput = AVAssetWriterInput(
                        mediaType: .video,
                        outputSettings: [
                            AVVideoCodecKey: AVVideoCodecType.h264,
                            AVVideoWidthKey: naturalSize.width,
                            AVVideoHeightKey: naturalSize.height
                        ]
                    )
                    videoInput.expectsMediaDataInRealTime = false
                    videoInput.transform = preferredTransform

                    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                        assetWriterInput: videoInput,
                        sourcePixelBufferAttributes: [
                            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                            kCVPixelBufferWidthKey as String: naturalSize.width,
                            kCVPixelBufferHeightKey as String: naturalSize.height
                        ]
                    )

                    guard writer.canAdd(videoInput) else {
                        throw VideoExporterError.unableToCreateWriter
                    }
                    writer.add(videoInput)

                    var audioInput: AVAssetWriterInput?
                    if audioOutput != nil {
                        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
                        input.expectsMediaDataInRealTime = false
                        if writer.canAdd(input) {
                            writer.add(input)
                            audioInput = input
                        }
                    }

                    guard reader.startReading() else {
                        throw reader.error ?? VideoExporterError.unableToCreateReader
                    }

                    guard writer.startWriting() else {
                        throw writer.error ?? VideoExporterError.unableToCreateWriter
                    }

                    writer.startSession(atSourceTime: .zero)

                    let detector = BlobDetector()
                    let tracker = BlobTracker()
                    var previousGrayscale: GrayscaleImage?

                    while let sampleBuffer = videoOutput.copyNextSampleBuffer() {
                        autoreleasepool {
                            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

                            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                            let frame = FrameData(pixelBuffer: imageBuffer, timestamp: timestamp)
                            let detectionResult = detector.detect(
                                in: frame,
                                settings: settings,
                                previousGrayscale: previousGrayscale
                            )
                            previousGrayscale = detectionResult.grayscale
                            let blobs = tracker.track(detections: detectionResult.detections, settings: settings)

                            guard
                                let annotatedBuffer = self.makeAnnotatedBuffer(
                                    from: imageBuffer,
                                    blobs: blobs,
                                    settings: settings,
                                    pool: adaptor.pixelBufferPool
                                )
                            else {
                                reader.cancelReading()
                                writer.cancelWriting()
                                return
                            }

                            while !videoInput.isReadyForMoreMediaData {
                                Thread.sleep(forTimeInterval: 0.0015)
                            }

                            if !adaptor.append(annotatedBuffer, withPresentationTime: timestamp) {
                                reader.cancelReading()
                                writer.cancelWriting()
                                return
                            }

                            progressHandler(min(CMTimeGetSeconds(timestamp) / durationSeconds, 0.98))
                        }
                    }

                    if reader.status == .failed {
                        throw reader.error ?? VideoExporterError.exportFailed
                    }

                    videoInput.markAsFinished()

                    if let audioOutput, let audioInput {
                        while let sampleBuffer = audioOutput.copyNextSampleBuffer() {
                            while !audioInput.isReadyForMoreMediaData {
                                Thread.sleep(forTimeInterval: 0.0015)
                            }

                            if !audioInput.append(sampleBuffer) {
                                throw writer.error ?? VideoExporterError.exportFailed
                            }
                        }

                        audioInput.markAsFinished()
                    }

                    writer.finishWriting {
                        if writer.status == .completed {
                            progressHandler(1)
                            continuation.resume(returning: outputURL)
                        } else {
                            continuation.resume(throwing: writer.error ?? VideoExporterError.exportFailed)
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func saveExportedVideoToPhotoLibrary(_ url: URL) async throws {
        try await requestAddPermission()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }, completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: VideoExporterError.exportFailed)
                }
            })
        }
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
            throw VideoExporterError.photoLibraryDenied
        }
    }

    private func makeAnnotatedBuffer(
        from pixelBuffer: CVPixelBuffer,
        blobs: [Blob],
        settings: TrackingSettings,
        pool: CVPixelBufferPool?
    ) -> CVPixelBuffer? {
        guard let cgImage = OverlayRenderer.renderAnnotatedImage(from: pixelBuffer, blobs: blobs, settings: settings) else {
            return nil
        }

        if let pool {
            var pooledBuffer: CVPixelBuffer?
            let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pooledBuffer)
            if status == kCVReturnSuccess, let pooledBuffer, let renderedBuffer = self.draw(cgImage: cgImage, into: pooledBuffer) {
                return renderedBuffer
            }
        }

        guard let buffer = CVPixelBuffer.make(width: cgImage.width, height: cgImage.height) else {
            return nil
        }

        return draw(cgImage: cgImage, into: buffer)
    }

    private func draw(cgImage: CGImage, into pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard
            let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
            let context = CGContext(
                data: baseAddress,
                width: cgImage.width,
                height: cgImage.height,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
            )
        else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        return pixelBuffer
    }
}
