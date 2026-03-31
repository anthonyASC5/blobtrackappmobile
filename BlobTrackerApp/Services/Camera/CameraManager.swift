import AVFoundation
import Foundation

protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput frame: FrameData)
    func cameraManager(_ manager: CameraManager, didUpdateAuthorization status: AVAuthorizationStatus)
}

final class CameraManager: NSObject {
    let session = AVCaptureSession()

    weak var delegate: CameraManagerDelegate?

    private let sessionQueue = DispatchQueue(label: "\(Constants.cameraQueueLabel).session")
    private let videoOutputQueue = DispatchQueue(label: "\(Constants.cameraQueueLabel).frames")
    private var isConfigured = false

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

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        session.beginConfiguration()
        session.sessionPreset = .high

        defer {
            session.commitConfiguration()
            isConfigured = true
        }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            return
        }

        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: videoOutputQueue)

        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        if let connection = output.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
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
