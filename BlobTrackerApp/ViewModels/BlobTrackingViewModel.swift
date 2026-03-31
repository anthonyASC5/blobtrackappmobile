import Combine
import CoreGraphics
import Foundation
import QuartzCore

final class BlobTrackingViewModel: ObservableObject, @unchecked Sendable {
    @Published private(set) var blobs: [Blob] = []
    @Published private(set) var framesPerSecond: Double = 0
    @Published private(set) var processingMilliseconds: Double = 0
    @Published private(set) var frameSize: CGSize = Constants.previewPlaceholderSize

    private let detector = BlobDetector()
    private let tracker = BlobTracker()
    private let processingQueue = DispatchQueue(label: Constants.processingQueueLabel)
    private var previousGrayscale: GrayscaleImage?
    private var currentSettings: TrackingSettings
    private var lastFPSUpdate = CACurrentMediaTime()
    private var frameCount = 0
    private var isEnabled = true
    private var subscriptions = Set<AnyCancellable>()

    @MainActor
    init(settingsStore: TrackingSettingsStore) {
        currentSettings = settingsStore.settings

        settingsStore.$settings
            .sink { [weak self] settings in
                self?.processingQueue.async {
                    self?.currentSettings = settings
                    self?.previousGrayscale = nil
                    self?.tracker.reset()
                }
            }
            .store(in: &subscriptions)
    }

    func setEnabled(_ enabled: Bool) {
        processingQueue.async {
            self.isEnabled = enabled
            if !enabled {
                self.previousGrayscale = nil
                self.tracker.reset()
                Task { @MainActor in
                    self.blobs = []
                }
            }
        }
    }

    func reset() {
        processingQueue.async {
            self.previousGrayscale = nil
            self.tracker.reset()
            Task { @MainActor in
                self.blobs = []
                self.framesPerSecond = 0
            }
        }
    }

    func process(frame: FrameData) {
        processingQueue.async {
            guard self.isEnabled else { return }

            let start = CACurrentMediaTime()
            let result = self.detector.detect(
                in: frame,
                settings: self.currentSettings,
                previousGrayscale: self.previousGrayscale
            )
            self.previousGrayscale = result.grayscale
            let blobs = self.tracker.track(detections: result.detections, settings: self.currentSettings)
            let elapsed = (CACurrentMediaTime() - start) * 1000

            self.frameCount += 1
            var fps = self.framesPerSecond
            let now = CACurrentMediaTime()
            if now - self.lastFPSUpdate >= 1 {
                fps = Double(self.frameCount) / (now - self.lastFPSUpdate)
                self.frameCount = 0
                self.lastFPSUpdate = now
            }

            Task { @MainActor in
                self.blobs = blobs
                self.frameSize = frame.size
                self.processingMilliseconds = elapsed
                self.framesPerSecond = fps
            }
        }
    }
}
