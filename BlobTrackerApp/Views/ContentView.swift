import SwiftUI

struct ContentView: View {
    @StateObject private var settingsStore: TrackingSettingsStore
    @StateObject private var cameraViewModel: CameraViewModel
    @StateObject private var videoViewModel: VideoViewModel

    init() {
        let settingsStore = TrackingSettingsStore()
        _settingsStore = StateObject(wrappedValue: settingsStore)
        _cameraViewModel = StateObject(wrappedValue: CameraViewModel(settingsStore: settingsStore))
        _videoViewModel = StateObject(wrappedValue: VideoViewModel(settingsStore: settingsStore))
    }

    var body: some View {
        TabView {
            NavigationStack {
                CameraView(viewModel: cameraViewModel, settingsStore: settingsStore)
            }
            .tabItem {
                Label("Live", systemImage: "camera.viewfinder")
            }

            NavigationStack {
                VideoPlayerView(viewModel: videoViewModel, settingsStore: settingsStore)
            }
            .tabItem {
                Label("Video", systemImage: "film.stack")
            }

            NavigationStack {
                SettingsView(settingsStore: settingsStore)
            }
            .tabItem {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
        }
        .tint(Color.accentColor)
    }
}
