import AVFoundation  // Import for camera authorization
import Combine  // Import for publishers
import CoreGraphics
import Foundation  // Import for basic types

@MainActor  // Ensures all code runs on main thread
final class CameraViewModel: NSObject, ObservableObject {  // View model for camera and tracking
    @Published private(set) var blobs: [Blob] = []  // Published array of detected blobs
    @Published private(set) var framesPerSecond: Double = 0  // FPS of processing
    @Published private(set) var processingMilliseconds: Double = 0  // Processing time
    @Published private(set) var sourceSize: CGSize = Constants.previewPlaceholderSize  // Source frame size
    @Published private(set) var latestFrame: FrameData?
    @Published private(set) var lidarPreviewImage: CGImage?
    @Published private(set) var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)  // Camera auth status
    @Published var isTrackingEnabled = true  // Flag for tracking on/off
    @Published var isRecording = false  // Flag for live recording
    @Published var cameraPosition: AVCaptureDevice.Position = .back  // Current camera position

    let settingsStore: TrackingSettingsStore  // Reference to settings

    private let cameraManager = CameraManager()  // Manager for camera
    private let trackingViewModel: BlobTrackingViewModel  // View model for tracking
    private let liveRecorder = LiveVideoRecorder()  // Live recording service
    private let depthRenderQueue = DispatchQueue(label: "\(Constants.cameraQueueLabel).depthRender")
    private var subscriptions = Set<AnyCancellable>()  // Subscriptions for publishers
    private var lastFrame: FrameData?
    private var lastBlobs: [Blob] = []
    private var pendingRecordingStart = false
    private var lidarPreviewFrameCounter = 0

    var session: AVCaptureSession { cameraManager.session }  // Expose session

    init(settingsStore: TrackingSettingsStore) {  // Initializer
        self.settingsStore = settingsStore  // Set settings
        trackingViewModel = BlobTrackingViewModel(settingsStore: settingsStore)  // Create tracking VM
        super.init()  // Call super

        cameraManager.delegate = self  // Set delegate
        cameraManager.setVisualEffectMode(settingsStore.settings.visualEffectMode)
        settingsStore.$settings
            .map(\.visualEffectMode)
            .removeDuplicates()
            .sink { [weak self] mode in
                self?.cameraManager.setVisualEffectMode(mode)
            }
            .store(in: &subscriptions)
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

    func resetTracking() {
        trackingViewModel.reset()
    }

    func toggleRecording() {
        if isRecording {
            isRecording = false
            pendingRecordingStart = false
            Task {
                do {
                    try await liveRecorder.finishAndSaveToPhotos()
                } catch {
                    // Ignore stop errors if the session never fully started.
                }
            }
        } else {
            isRecording = true
            if let frame = lastFrame {
                pendingRecordingStart = false
                liveRecorder.beginRecording(frame: frame, blobs: lastBlobs, settings: settingsStore.settings)
            } else {
                pendingRecordingStart = true
            }
        }
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

    private func updateLidarPreview(from frame: FrameData) {
        latestFrame = frame

        guard
            settingsStore.settings.visualEffectMode == .lidarScan,
            let depthPixelBuffer = frame.depthPixelBuffer
        else {
            lidarPreviewImage = nil
            return
        }

        lidarPreviewFrameCounter += 1
        guard lidarPreviewFrameCounter.isMultiple(of: 2) else { return }

        depthRenderQueue.async { [weak self] in
            let rendered = DepthMapRenderer.renderDepthScan(
                from: depthPixelBuffer,
                maxDepthMeters: 4.5,
                scaleFactor: 0.75
            )

            Task { @MainActor [weak self] in
                guard let self, self.settingsStore.settings.visualEffectMode == .lidarScan else { return }
                self.lidarPreviewImage = rendered
            }
        }
    }
}

extension CameraViewModel: CameraManagerDelegate {
    nonisolated func cameraManager(_ manager: CameraManager, didOutput frame: FrameData) {
        Task { @MainActor [weak self] in
            self?.updateLidarPreview(from: frame)
            self?.trackingViewModel.process(frame: frame) { blobs in
                Task { @MainActor [weak self] in
                    self?.handleProcessedFrame(frame: frame, blobs: blobs)
                }
            }
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

    private func handleProcessedFrame(frame: FrameData, blobs: [Blob]) {
        lastFrame = frame
        lastBlobs = blobs

        guard isRecording else { return }

        if pendingRecordingStart {
            pendingRecordingStart = false
            liveRecorder.beginRecording(frame: frame, blobs: blobs, settings: settingsStore.settings)
        } else {
            liveRecorder.append(frame: frame, blobs: blobs, settings: settingsStore.settings)
        }
    }
}
