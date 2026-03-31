import AVFoundation
import AVKit
import Combine
import Foundation

@MainActor
final class VideoViewModel: ObservableObject {
    @Published private(set) var blobs: [Blob] = []
    @Published private(set) var sourceSize: CGSize = Constants.previewPlaceholderSize
    @Published private(set) var duration: Double = 1
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var framesPerSecond: Double = 0
    @Published private(set) var processingMilliseconds: Double = 0
    @Published private(set) var statusMessage: String?
    @Published private(set) var isExporting = false
    @Published private(set) var exportProgress: Double = 0
    @Published private(set) var exportStatusMessage: String?
    @Published var isPresentingPicker = false

    let player = AVPlayer()
    let settingsStore: TrackingSettingsStore

    private let loader = VideoLoader()
    private let trackingViewModel: BlobTrackingViewModel
    private let exportViewModel: ExportViewModel
    private var frameExtractor: FrameExtractor?
    private var selectedSource: VideoSource?
    private var latestFrame: FrameData?
    private var playbackObserver: Any?
    private var pendingAnalysisTime: CMTime?
    private var analysisTask: Task<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()

    var hasVideo: Bool { selectedSource != nil }
    var activeMessage: String? { exportStatusMessage ?? statusMessage }

    init(settingsStore: TrackingSettingsStore) {
        self.settingsStore = settingsStore
        trackingViewModel = BlobTrackingViewModel(settingsStore: settingsStore)
        exportViewModel = ExportViewModel(settingsStore: settingsStore)
        bindState()
    }

    func presentPicker() {
        isPresentingPicker = true
    }

    func handlePickedVideo(url: URL) {
        isPresentingPicker = false
        statusMessage = "Loading video..."

        Task {
            do {
                let source = try await loader.prepareVideo(from: url)
                try await loadSource(source)
                statusMessage = "Video ready for tracking."
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    func togglePlayback() {
        guard hasVideo else {
            presentPicker()
            return
        }

        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func seek(to progress: Double) {
        guard hasVideo else { return }
        let clampedProgress = MathUtils.clamp(progress, lower: 0, upper: 1)
        let time = CMTime(seconds: duration * clampedProgress, preferredTimescale: 600)

        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            guard finished else { return }
            Task { @MainActor in
                self?.currentTime = CMTimeGetSeconds(time)
                self?.scheduleAnalysis(at: time)
            }
        }
    }

    func saveCurrentFrame() {
        guard let latestFrame else {
            statusMessage = "Analyze a frame before exporting."
            return
        }

        exportViewModel.saveCurrentFrame(frame: latestFrame, blobs: blobs)
    }

    func exportProcessedVideo() {
        guard let selectedSource else {
            statusMessage = "Import a video before exporting."
            return
        }

        exportViewModel.exportProcessedVideo(asset: selectedSource.asset)
    }

    private func bindState() {
        trackingViewModel.$blobs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.blobs = $0 }
            .store(in: &subscriptions)

        trackingViewModel.$frameSize
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sourceSize = $0 }
            .store(in: &subscriptions)

        trackingViewModel.$framesPerSecond
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.framesPerSecond = $0 }
            .store(in: &subscriptions)

        trackingViewModel.$processingMilliseconds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.processingMilliseconds = $0 }
            .store(in: &subscriptions)

        exportViewModel.$isExporting
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isExporting = $0 }
            .store(in: &subscriptions)

        exportViewModel.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.exportProgress = $0 }
            .store(in: &subscriptions)

        exportViewModel.$statusMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.exportStatusMessage = $0 }
            .store(in: &subscriptions)

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self, notification.object as? AVPlayerItem === self.player.currentItem else { return }
                self.isPlaying = false
            }
            .store(in: &subscriptions)
    }

    private func loadSource(_ source: VideoSource) async throws {
        selectedSource = source
        frameExtractor = FrameExtractor(asset: source.asset)
        trackingViewModel.reset()

        if let playbackObserver {
            player.removeTimeObserver(playbackObserver)
            self.playbackObserver = nil
        }

        let assetDuration = try await source.asset.load(.duration)
        duration = max(CMTimeGetSeconds(assetDuration), 0.01)
        sourceSize = try await frameExtractor?.videoSize() ?? Constants.previewPlaceholderSize

        let item = AVPlayerItem(asset: source.asset)
        player.replaceCurrentItem(with: item)
        player.pause()
        isPlaying = false
        currentTime = 0

        playbackObserver = player.addPeriodicTimeObserver(forInterval: Constants.analysisInterval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentTime = CMTimeGetSeconds(time)
                self.isPlaying = self.player.rate > 0
                self.scheduleAnalysis(at: time)
            }
        }

        scheduleAnalysis(at: .zero)
    }

    private func scheduleAnalysis(at time: CMTime) {
        pendingAnalysisTime = time

        guard analysisTask == nil else { return }

        analysisTask = Task { [weak self] in
            while let pendingTime = self?.pendingAnalysisTime {
                self?.pendingAnalysisTime = nil
                await self?.analyze(at: pendingTime)
            }

            self?.analysisTask = nil
        }
    }

    private func analyze(at time: CMTime) async {
        guard let frameExtractor else { return }

        do {
            let frame = try await frameExtractor.extractFrame(at: time)
            latestFrame = frame
            trackingViewModel.process(frame: frame)
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
