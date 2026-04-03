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
            ZStack(alignment: .topLeading) {
                CameraPreview(session: viewModel.session)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .brightness(settingsStore.settings.brightness)
                    .contrast(settingsStore.settings.contrast)
                    .saturation(settingsStore.settings.blackAndWhite ? 0 : settingsStore.settings.saturation)
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
                        Button(action: {
                            let next: BlobColorMode
                            switch settingsStore.settings.blobColorMode {
                            case .white: next = .rainbow
                            case .rainbow: next = .red
                            case .red: next = .white
                            }
                            settingsStore.settings.blobColorMode = next
                        }) {
                            Text(settingsStore.settings.blobColorMode.displayName)
                                .font(.caption.bold())
                                .foregroundColor(settingsStore.settings.blobColorMode == .white ? .black : .white)
                                .padding(12)
                                .background(
                                    Rectangle()
                                        .fill(settingsStore.settings.blobColorMode == .white ? Color.white : settingsStore.settings.blobColorMode == .red ? Color.red : Color.purple)
                                )
                                .cornerRadius(12)
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

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.videoGravity = .resizeAspect
        view.previewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
