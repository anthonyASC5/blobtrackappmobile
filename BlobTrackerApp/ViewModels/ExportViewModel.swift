import AVFoundation
import Foundation

@MainActor
final class ExportViewModel: ObservableObject {
    @Published private(set) var isExporting = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var statusMessage: String?

    private let frameWriter = FrameWriter()
    private let videoExporter = VideoExporter()
    private let settingsStore: TrackingSettingsStore

    init(settingsStore: TrackingSettingsStore) {
        self.settingsStore = settingsStore
    }

    func saveCurrentFrame(frame: FrameData, blobs: [Blob]) {
        statusMessage = nil

        Task {
            do {
                try await frameWriter.saveAnnotatedFrame(frame: frame, blobs: blobs, settings: settingsStore.settings)
                statusMessage = "Saved annotated frame to Photos."
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    func exportProcessedVideo(asset: AVAsset) {
        isExporting = true
        progress = 0
        statusMessage = "Rendering processed video..."

        Task {
            do {
                let exportedURL = try await videoExporter.exportProcessedVideo(
                    asset: asset,
                    settings: settingsStore.settings,
                    progressHandler: { [weak self] progress in
                        Task { @MainActor in
                            self?.progress = progress
                        }
                    }
                )
                try await videoExporter.saveExportedVideoToPhotoLibrary(exportedURL)
                statusMessage = "Saved processed video to Photos."
            } catch {
                statusMessage = error.localizedDescription
            }

            isExporting = false
        }
    }
}
