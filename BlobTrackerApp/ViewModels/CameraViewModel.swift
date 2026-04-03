import AVFoundation  // Import for camera authorization
import Combine  // Import for publishers
import Foundation  // Import for basic types

@MainActor  // Ensures all code runs on main thread
final class CameraViewModel: NSObject, ObservableObject {  // View model for camera and tracking
    @Published private(set) var blobs: [Blob] = []  // Published array of detected blobs
    @Published private(set) var framesPerSecond: Double = 0  // FPS of processing
    @Published private(set) var processingMilliseconds: Double = 0  // Processing time
    @Published private(set) var sourceSize: CGSize = Constants.previewPlaceholderSize  // Source frame size
    @Published private(set) var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)  // Camera auth status
    @Published var isTrackingEnabled = true  // Flag for tracking on/off
    @Published var cameraPosition: AVCaptureDevice.Position = .back  // Current camera position

    let settingsStore: TrackingSettingsStore  // Reference to settings

    private let cameraManager = CameraManager()  // Manager for camera
    private let trackingViewModel: BlobTrackingViewModel  // View model for tracking
    private var subscriptions = Set<AnyCancellable>()  // Subscriptions for publishers

    var session: AVCaptureSession { cameraManager.session }  // Expose session

    init(settingsStore: TrackingSettingsStore) {  // Initializer
        self.settingsStore = settingsStore  // Set settings
        trackingViewModel = BlobTrackingViewModel(settingsStore: settingsStore)  // Create tracking VM
        super.init()  // Call super

        cameraManager.delegate = self  // Set delegate
        bindTrackingState()  // Bind state
    }

    func start() {  // Starts camera
        cameraManager.requestAccessIfNeeded()  // Request access
        cameraPosition = cameraManager.activePosition  // Sync position
    }

    func stop() {  // Stops camera
        cameraManager.stopRunning()  // Stop running
    }

    func toggleTracking() {  // Toggles tracking
        isTrackingEnabled.toggle()  // Toggle flag
        trackingViewModel.setEnabled(isTrackingEnabled)  // Set in tracking VM
    }

    func flipCamera() {  // Flips camera
        cameraManager.flipCamera()  // Call manager
        cameraPosition = cameraManager.activePosition == .back ? .front : .back  // update state immediately
        if cameraPosition == .front {  // Selfie default to wide
            setCameraType(.wide)
        }
    }

    func setCameraType(_ type: CameraType) {  // Sets camera type
        let resolvedType: CameraType = cameraPosition == .front ? .wide : type  // front only wide
        cameraManager.setCameraType(resolvedType)  // Call manager
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
