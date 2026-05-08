import SwiftUI  // Import SwiftUI framework for UI components

@main  // Marks the entry point of the app
struct BlobTrackerApp: App {  // Main app structure conforming to App protocol
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate  // Adapts UIKit AppDelegate for SwiftUI
    @State private var showIntro = true  // State to control intro screen display

    var body: some Scene {  // Defines the app's scene
        WindowGroup {  // Creates a window group for the app
            if showIntro {  // Conditional view based on intro state
                BlobIntroView {  // Shows intro view with completion handler
                    showIntro = false  // Hides intro after completion
                }
            } else {  // Shows main content after intro
                ContentView()  // Main content view of the app
            }
        }
    }
}
