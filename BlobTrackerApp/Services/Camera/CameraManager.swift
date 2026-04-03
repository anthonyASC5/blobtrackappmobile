import AVFoundation  // Import for camera and video capture
import Foundation  // Import for basic types

protocol CameraManagerDelegate: AnyObject {  // Protocol for camera events
    func cameraManager(_ manager: CameraManager, didOutput frame: FrameData)  // Called when frame is captured
    func cameraManager(_ manager: CameraManager, didUpdateAuthorization status: AVAuthorizationStatus)  // Called when auth changes
}

enum CameraType {  // Enum for camera lens types
    case wide  // Wide angle lens
    case ultraWide  // Ultra wide lens
}

final class CameraManager: NSObject {  // Class managing camera capture session
    let session = AVCaptureSession()  // The capture session

    weak var delegate: CameraManagerDelegate?  // Delegate for events

    private let sessionQueue = DispatchQueue(label: "\(Constants.cameraQueueLabel).session")  // Queue for session operations
    private let videoOutputQueue = DispatchQueue(label: "\(Constants.cameraQueueLabel).frames")  // Queue for frame processing
    private var isConfigured = false  // Flag if session is configured
    private var currentPosition: AVCaptureDevice.Position = .back  // Current camera position
    private var currentType: CameraType = .wide  // Current camera type
    private var currentInput: AVCaptureDeviceInput?  // Current input device

    var activePosition: AVCaptureDevice.Position { currentPosition }  // Expose current position
    var activeType: CameraType { currentType }  // Expose current lens type

    func requestAccessIfNeeded() {  // Requests camera access if needed
        let status = AVCaptureDevice.authorizationStatus(for: .video)  // Get current auth status

        switch status {  // Handle different auth statuses
        case .authorized:  // Already authorized
            delegate?.cameraManager(self, didUpdateAuthorization: status)  // Notify delegate

        case .notDetermined:  // Not determined yet
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in  // Request access
                guard let self else { return }  // Weak self check
                DispatchQueue.main.async {  // Dispatch to main
                    self.delegate?.cameraManager(self, didUpdateAuthorization: granted ? .authorized : .denied)  // Notify
                }
            }

        case .denied, .restricted:  // Denied or restricted
            delegate?.cameraManager(self, didUpdateAuthorization: status)  // Notify

        @unknown default:  // Unknown status
            delegate?.cameraManager(self, didUpdateAuthorization: .restricted)  // Treat as restricted
        }
    }

    func startRunning() {  // Starts the capture session
        sessionQueue.async { [weak self] in  // Async on session queue
            guard let self else { return }  // Weak self
            self.configureIfNeeded()  // Configure if not done

            guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else { return }  // Check auth
            guard !self.session.isRunning else { return }  // Check if running
            self.session.startRunning()  // Start session
        }
    }

    func stopRunning() {  // Stops the capture session
        sessionQueue.async { [weak self] in  // Async on session queue
            guard let self, self.session.isRunning else { return }  // Check if running
            self.session.stopRunning()  // Stop session
        }
    }

    func flipCamera() {  // Flips between front and back camera
        sessionQueue.async { [weak self] in  // Async
            guard let self else { return }  // Weak self
            self.currentPosition = self.currentPosition == .back ? .front : .back  // Toggle position
            if self.currentPosition == .front {  // Front selfie defaults to wide
                self.currentType = .wide
            }
            self.reconfigureCamera()  // Reconfigure with new position
        }
    }

    func setCameraType(_ type: CameraType) {  // Sets the camera lens type
        sessionQueue.async { [weak self] in  // Async
            guard let self else { return }  // Weak self
            self.currentType = type  // Set type
            self.reconfigureCamera()  // Reconfigure with new type
        }
    }

    private func reconfigureCamera() {  // Reconfigures the camera with current settings
        guard isConfigured else { return }  // Check if configured
        session.beginConfiguration()  // Begin config
        defer { session.commitConfiguration() }  // Commit at end

        // Remove current input
        if let currentInput {  // If has input
            session.removeInput(currentInput)  // Remove it
        }

        // Add new input
        guard let device = self.deviceForCurrentSettings(),  // Get device
              let input = try? AVCaptureDeviceInput(device: device),  // Create input
              session.canAddInput(input) else {  // Check can add
            return  // Return if not
        }

        session.addInput(input)  // Add input
        currentInput = input  // Store input
    }

    private func configureIfNeeded() {  // Configures session if not done
        guard !isConfigured else { return }  // Check flag
        session.beginConfiguration()  // Begin config
        session.sessionPreset = .high  // Set preset

        defer {  // Defer commit
            session.commitConfiguration()  // Commit
            isConfigured = true  // Set flag
        }

        guard  // Guard for device and input
            let device = deviceForCurrentSettings(),  // Get device
            let input = try? AVCaptureDeviceInput(device: device),  // Create input
            session.canAddInput(input)  // Check can add
        else {
            return  // Return if fail
        }

        session.addInput(input)  // Add input
        currentInput = input  // Store

        let output = AVCaptureVideoDataOutput()  // Create output
        output.alwaysDiscardsLateVideoFrames = true  // Discard late frames
        output.videoSettings = [  // Set video settings
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: videoOutputQueue)  // Set delegate

        guard session.canAddOutput(output) else { return }  // Check can add output
        session.addOutput(output)  // Add output

        if let connection = output.connection(with: .video), connection.isVideoRotationAngleSupported(90) {  // Set rotation
            connection.videoRotationAngle = 90
        }
    }

    private func deviceForCurrentSettings() -> AVCaptureDevice? {  // Gets device for current settings
        let deviceType: AVCaptureDevice.DeviceType  // Device type var
        switch currentType {  // Switch on type
        case .wide:  // Wide
            deviceType = .builtInWideAngleCamera  // Set to wide
        case .ultraWide:  // Ultra wide
            deviceType = .builtInUltraWideCamera  // Set to ultra wide
        }
        return AVCaptureDevice.default(deviceType, for: .video, position: currentPosition)  // Return default device
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {  // Extension for delegate
    func captureOutput(  // Delegate method for frame output
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let frame = FrameCapture.makeFrameData(from: sampleBuffer) else { return }  // Make frame data
        delegate?.cameraManager(self, didOutput: frame)  // Notify delegate
    }
}
