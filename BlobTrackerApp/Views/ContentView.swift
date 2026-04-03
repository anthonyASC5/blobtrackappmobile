import SwiftUI  // Import SwiftUI for building the user interface

struct ContentView: View {  // Main content view with tab navigation
    @StateObject private var settingsStore: TrackingSettingsStore  // State object for tracking settings
    @StateObject private var cameraViewModel: CameraViewModel  // View model for camera functionality
    @StateObject private var videoViewModel: VideoViewModel  // View model for video playback

    init() {  // Custom initializer to set up view models
        let settingsStore = TrackingSettingsStore()  // Create shared settings store
        _settingsStore = StateObject(wrappedValue: settingsStore)  // Initialize state object
        _cameraViewModel = StateObject(wrappedValue: CameraViewModel(settingsStore: settingsStore))  // Initialize camera view model
        _videoViewModel = StateObject(wrappedValue: VideoViewModel(settingsStore: settingsStore))  // Initialize video view model
    }

    var body: some View {  // Body of the view defining the UI
        TabView {  // Tab view for navigation between sections
            NavigationStack {  // Navigation stack for live camera view
                CameraView(viewModel: cameraViewModel, settingsStore: settingsStore)  // Camera view with models
            }
            .tabItem {  // Tab item for live section
                Label("Live", systemImage: "camera.viewfinder")  // Label with text and icon
            }

            NavigationStack {  // Navigation stack for video player view
                VideoPlayerView(viewModel: videoViewModel, settingsStore: settingsStore)  // Video player view
            }
            .tabItem {  // Tab item for video section
                Label("Video", systemImage: "film.stack")  // Label with text and icon
            }

            NavigationStack {  // Navigation stack for settings view
                SettingsView(settingsStore: settingsStore)  // Settings view
            }
            .tabItem {  // Tab item for settings section
                Label("Settings", systemImage: "slider.horizontal.3")  // Label with text and icon
            }
        }
        .tint(Color.pink)  // Set accent color to pink for the tab view
    }
}
