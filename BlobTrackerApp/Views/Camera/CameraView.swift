import AVFoundation
import SwiftUI
import UIKit

struct CameraView: View {
    @ObservedObject var viewModel: CameraViewModel
    @ObservedObject var settingsStore: TrackingSettingsStore

    var body: some View {
        ZStack {
            if viewModel.authorizationStatus == .denied || viewModel.authorizationStatus == .restricted {
                permissionView
            } else {
                liveCameraView
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Live Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: viewModel.start)
        .onDisappear(perform: viewModel.stop)
    }

    private var liveCameraView: some View {
        GeometryReader { geometry in
            let effectMode = settingsStore.settings.visualEffectMode
            ZStack(alignment: .topLeading) {
                Group {
                    if effectMode == .lidarScan, let depthImage = viewModel.lidarPreviewImage {
                        Image(decorative: depthImage, scale: 1, orientation: .up)
                            .resizable()
                            .scaledToFit()
                            .overlay(lidarScanOverlay)
                    } else {
                        CameraPreview(session: viewModel.session)
                            .brightness(settingsStore.settings.brightness)
                            .contrast(settingsStore.settings.contrast)
                            .saturation(settingsStore.settings.blackAndWhite ? 0 : settingsStore.settings.saturation)
                            .hueRotation(.degrees(settingsStore.settings.hueShift))
                            .modifier(CameraFXPreviewModifier(effectMode: effectMode))
                    }
                }
                .frame(width: geometry.size.width - 32, height: geometry.size.height - 32)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
                .padding(16)

                BlobOverlayView(
                    blobs: viewModel.blobs,
                    sourceSize: viewModel.sourceSize,
                    settings: settingsStore.settings
                )
                .padding(16)

                // Middle screen blob color mode button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            BlobColorModeButton(
                                mode: settingsStore.settings.blobColorMode,
                                title: settingsStore.settings.blobColorMode.displayName
                            ) {
                                let next: BlobColorMode
                                switch settingsStore.settings.blobColorMode {
                                case .white: next = .rainbow
                                case .rainbow: next = .red
                                case .red: next = .neonBlue
                                case .neonBlue: next = .white
                                }
                                settingsStore.settings.blobColorMode = next
                            }
                            .frame(width: 116)

                            Button(action: viewModel.toggleRecording) {
                                Image(systemName: viewModel.isRecording ? "stop.fill" : "record.circle")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(viewModel.isRecording ? .white : .red)
                                    .frame(width: 28, height: 28)
                                    .background {
                                        Circle()
                                            .fill(viewModel.isRecording ? Color.red : Color.white.opacity(0.92))
                                    }
                                    .overlay {
                                        Circle()
                                            .strokeBorder(Color.white.opacity(viewModel.isRecording ? 0.0 : 0.18), lineWidth: 1)
                                    }
                                    .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(viewModel.isRecording ? "Stop Recording" : "Record Video")
                        }
                        Spacer()
                    }
                    Spacer().frame(height: 260)
                }

                if settingsStore.settings.showDebugInfo {
                    DebugOverlayView(
                        mode: settingsStore.settings.detectionMode,
                        framesPerSecond: viewModel.framesPerSecond,
                        processingMilliseconds: viewModel.processingMilliseconds,
                        blobCount: viewModel.blobs.count
                    )
                    .padding(28)
                }

                VStack {
                    Spacer()
                    CameraControls(viewModel: viewModel, settingsStore: settingsStore)
                        .padding(.horizontal, 16)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom + 12, 28))
                }
            }
        }
    }

    private var lidarScanOverlay: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.20),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 3)
            .offset(y: proxy.size.height * 0.35)
            .blendMode(.screen)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .offset(y: proxy.size.height * 0.35)
                    .blendMode(.screen)
            }
        }
        .allowsHitTesting(false)
    }

    private var permissionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 42))
                .foregroundStyle(.white)
            Text("Camera Access Needed")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text("Enable camera access in Settings to use live blob tracking.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: 320)
            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}

private struct CameraFXPreviewModifier: ViewModifier {
    let effectMode: VisualEffectMode

    @ViewBuilder
    func body(content: Content) -> some View {
        switch effectMode {
        case .off:
            content
        case .nightVision:
            content
                .saturation(0.12)
                .contrast(1.75)
                .brightness(-0.06)
                .colorMultiply(Color(red: 0.18, green: 0.82, blue: 0.24))
        case .lidarScan:
            content
        }
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.videoGravity = .resizeAspect
        view.previewLayer.session = session
        // Set the preview layer immediately so the live feed fills the SwiftUI container correctly.
        view.previewLayer.frame = view.bounds
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
        uiView.previewLayer.frame = uiView.bounds
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Keep the AVCapture preview layer locked to the UIView bounds during layout changes.
        previewLayer.frame = bounds
    }
}
