import AVKit
import SwiftUI

struct VideoPlayerView: View {
    @ObservedObject var viewModel: VideoViewModel
    @ObservedObject var settingsStore: TrackingSettingsStore

    var body: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.13, green: 0.15, blue: 0.2),
                                Color(red: 0.04, green: 0.05, blue: 0.09)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if viewModel.hasVideo {
                    VideoPlayer(player: viewModel.player)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                    BlobOverlayView(
                        blobs: viewModel.blobs,
                        sourceSize: viewModel.sourceSize,
                        settings: settingsStore.settings
                    )

                    if settingsStore.settings.showDebugInfo {
                        DebugOverlayView(
                            mode: settingsStore.settings.detectionMode,
                            framesPerSecond: viewModel.framesPerSecond,
                            processingMilliseconds: viewModel.processingMilliseconds,
                            blobCount: viewModel.blobs.count
                        )
                        .padding(20)
                    }
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 42))
                        Text("Import a video to analyze blobs frame by frame.")
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 260)
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .aspectRatio(max(viewModel.sourceSize.width, 1) / max(viewModel.sourceSize.height, 1), contentMode: .fit)

            VideoTimelineView(
                currentTime: viewModel.currentTime,
                duration: viewModel.duration,
                onScrub: viewModel.seek(to:)
            )

            HStack(spacing: 12) {
                Button(action: viewModel.presentPicker) {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: viewModel.togglePlayback) {
                    Label(viewModel.isPlaying ? "Pause" : "Play", systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: viewModel.saveCurrentFrame) {
                    Label("Frame", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: viewModel.exportProcessedVideo) {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.hasVideo || viewModel.isExporting)
            }

            if viewModel.isExporting {
                ProgressView(value: viewModel.exportProgress)
                    .tint(.accentColor)
            }

            if let message = viewModel.activeMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .navigationTitle("Video Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isPresentingPicker) {
            VideoPickerView(
                onPick: viewModel.handlePickedVideo(url:),
                onCancel: { viewModel.isPresentingPicker = false }
            )
        }
    }
}
