import AVFoundation
import Foundation

protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput frame: FrameData)
    func cameraManager(_ manager: CameraManager, didUpdateAuthorization status: AVAuthorizationStatus)
}

enum CameraType {
    case wide
    case ultraWide
}

final class CameraManager: NSObject {
    let session = AVCaptureSession()

    weak var delegate: CameraManagerDelegate?

    private let sessionQueue = DispatchQueue(label: "\(Constants.cameraQueueLabel).session")
    private let videoOutputQueue = DispatchQueue(label: "\(Constants.cameraQueueLabel).frames")

    private var isConfigured = false
    private var currentPosition: AVCaptureDevice.Position = .back
    private var currentType: CameraType = .wide
    private var currentEffectMode: VisualEffectMode = .off
    private var currentInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var depthOutput: AVCaptureDepthDataOutput?
    private var synchronizer: AVCaptureDataOutputSynchronizer?

    var activePosition: AVCaptureDevice.Position { currentPosition }
    var activeType: CameraType { currentType }

    func requestAccessIfNeeded() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            delegate?.cameraManager(self, didUpdateAuthorization: status)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.delegate?.cameraManager(self, didUpdateAuthorization: granted ? .authorized : .denied)
                }
            }

        case .denied, .restricted:
            delegate?.cameraManager(self, didUpdateAuthorization: status)

        @unknown default:
            delegate?.cameraManager(self, didUpdateAuthorization: .restricted)
        }
    }

    func startRunning() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configureIfNeeded()

            guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else { return }
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopRunning() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.currentEffectMode != .lidarScan else { return }
            self.currentPosition = self.currentPosition == .back ? .front : .back
            if self.currentPosition == .front {
                self.currentType = .wide
            }
            self.reconfigureSession()
        }
    }

    func setCameraType(_ type: CameraType) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.currentEffectMode != .lidarScan else { return }
            self.currentType = type
            self.reconfigureSession()
        }
    }

    func setVisualEffectMode(_ mode: VisualEffectMode) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.currentEffectMode != mode else { return }
            let needsReconfigure = (self.currentEffectMode == .lidarScan) || (mode == .lidarScan)
            self.currentEffectMode = mode

            if mode == .lidarScan {
                self.currentPosition = .back
                self.currentType = .wide
            }

            if needsReconfigure {
                self.reconfigureSession()
            }
        }
    }

    private func configureIfNeeded() {
        guard !isConfigured else { returplean }
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
            isConfigured = true
        }

        session.sessionPreset = .high

        guard configureCurrentInput() else { return }
        configureCurrentOutputs()
    }

    private func reconfigureSession() {
        guard isConfigured else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        removeCurrentPipeline()
        guard configureCurrentInput() else { return }
        configureCurrentOutputs()
    }

    private func removeCurrentPipeline() {
        if let currentInput {
            session.removeInput(currentInput)
        }

        session.outputs.forEach { session.removeOutput($0) }
        currentInput = nil
        videoOutput = nil
        depthOutput = nil
        synchronizer = nil
    }

    private func configureCurrentInput() -> Bool {
        guard let device = deviceForCurrentSettings() else {
            return false
        }

        if currentEffectMode == .lidarScan && currentPosition == .back {
            _ = configureLiDARDevice(device)
        }

        guard let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
            return false
        }

        session.addInput(input)
        currentInput = input
        return true
    }

    private func configureCurrentOutputs() {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        guard session.canAddOutput(videoOutput) else { return }
        session.addOutput(videoOutput)

        if currentEffectMode == .lidarScan,
           currentPosition == .back,
           let depthOutput = makeDepthOutput(),
           session.canAddOutput(depthOutput) {
            session.addOutput(depthOutput)

            let synchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [videoOutput, depthOutput])
            synchronizer.setDelegate(self, queue: videoOutputQueue)

            self.videoOutput = videoOutput
            self.depthOutput = depthOutput
            self.synchronizer = synchronizer
        } else {
            videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
            self.videoOutput = videoOutput
            self.depthOutput = nil
            self.synchronizer = nil
        }

        if let connection = videoOutput.connection(with: .video),
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }

    private func makeDepthOutput() -> AVCaptureDepthDataOutput? {
        let depthOutput = AVCaptureDepthDataOutput()
        depthOutput.isFilteringEnabled = true
        depthOutput.alwaysDiscardsLateDepthData = true
        return depthOutput
    }

    private func configureLiDARDevice(_ device: AVCaptureDevice) -> Bool {
        guard
            let format = device.formats.last(where: { format in
                format.formatDescription.dimensions.width >= 640 &&
                format.formatDescription.mediaSubType.rawValue == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange &&
                !format.isVideoBinned &&
                !format.supportedDepthDataFormats.isEmpty
            }),
            let depthFormat = format.supportedDepthDataFormats.last(where: { depthFormat in
                depthFormat.formatDescription.mediaSubType.rawValue == kCVPixelFormatType_DepthFloat16
            })
        else {
            return false
        }

        do {
            try device.lockForConfiguration()
            device.activeFormat = format
            device.activeDepthDataFormat = depthFormat
            device.unlockForConfiguration()
            return true
        } catch {
            return false
        }
    }

    private func deviceForCurrentSettings() -> AVCaptureDevice? {
        if currentEffectMode == .lidarScan,
           currentPosition == .back,
           let lidar = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) {
            return lidar
        }

        let deviceType: AVCaptureDevice.DeviceType
        switch currentType {
        case .wide:
            deviceType = .builtInWideAngleCamera
        case .ultraWide:
            deviceType = .builtInUltraWideCamera
        }
        return AVCaptureDevice.default(deviceType, for: .video, position: currentPosition)
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let frame = FrameCapture.makeFrameData(from: sampleBuffer) else { return }
        delegate?.cameraManager(self, didOutput: frame)
    }
}

extension CameraManager: AVCaptureDataOutputSynchronizerDelegate {
    func dataOutputSynchronizer(
        _ synchronizer: AVCaptureDataOutputSynchronizer,
        didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection
    ) {
        guard
            let videoOutput,
            let syncedVideoData = synchronizedDataCollection.synchronizedData(for: videoOutput) as? AVCaptureSynchronizedSampleBufferData,
            !syncedVideoData.sampleBufferWasDropped,
            let pixelBuffer = CMSampleBufferGetImageBuffer(syncedVideoData.sampleBuffer)
        else {
            return
        }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(syncedVideoData.sampleBuffer)
        var depthPixelBuffer: CVPixelBuffer?

        if let depthOutput,
           let syncedDepthData = synchronizedDataCollection.synchronizedData(for: depthOutput) as? AVCaptureSynchronizedDepthData,
           !syncedDepthData.depthDataWasDropped {
            depthPixelBuffer = syncedDepthData.depthData.converting(toDepthDataType: kCVPixelFormatType_DepthFloat16).depthDataMap
        }

        delegate?.cameraManager(
            self,
            didOutput: FrameData(
                pixelBuffer: pixelBuffer,
                timestamp: timestamp,
                depthPixelBuffer: depthPixelBuffer
            )
        )
    }
}
