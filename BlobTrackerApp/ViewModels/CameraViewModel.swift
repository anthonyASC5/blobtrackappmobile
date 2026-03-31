import AVFoundation
import Combine
import Foundation

@MainActor
final class CameraViewModel: NSObject, ObservableObject {
    @Published private(set) var blobs: [Blob] = []
    @Published private(set) var framesPerSecond: Double = 0
    @Published private(set) var processingMilliseconds: Double = 0
    @Published private(set) var sourceSize: CGSize = Constants.previewPlaceholderSize
    @Published private(set) var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published var isTrackingEnabled = true

    let settingsStore: TrackingSettingsStore

    private let cameraManager = CameraManager()
    private let trackingViewModel: BlobTrackingViewModel
    private var subscriptions = Set<AnyCancellable>()

    var session: AVCaptureSession { cameraManager.session }

    init(settingsStore: TrackingSettingsStore) {
        self.settingsStore = settingsStore
        trackingViewModel = BlobTrackingViewModel(settingsStore: settingsStore)
        super.init()

        cameraManager.delegate = self
        bindTrackingState()
    }

    func start() {
        cameraManager.requestAccessIfNeeded()
    }

    func stop() {
        cameraManager.stopRunning()
    }

    func toggleTracking() {
        isTrackingEnabled.toggle()
        trackingViewModel.setEnabled(isTrackingEnabled)
    }

    private func bindTrackingState() {
        trackingViewModel.$blobs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.blobs = $0 }
            .store(in: &subscriptions)

        trackingViewModel.$framesPerSecond
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.framesPerSecond = $0 }
            .store(in: &subscriptions)

        trackingViewModel.$processingMilliseconds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.processingMilliseconds = $0 }
            .store(in: &subscriptions)

        trackingViewModel.$frameSize
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sourceSize = $0 }
            .store(in: &subscriptions)
    }
}

extension CameraViewModel: CameraManagerDelegate {
    nonisolated func cameraManager(_ manager: CameraManager, didOutput frame: FrameData) {
        Task { @MainActor [weak self] in
            self?.trackingViewModel.process(frame: frame)
        }
    }

    nonisolated func cameraManager(_ manager: CameraManager, didUpdateAuthorization status: AVAuthorizationStatus) {
        Task { @MainActor [weak self] in
            self?.authorizationStatus = status
            if status == .authorized {
                manager.startRunning()
            }
        }
    }
}
