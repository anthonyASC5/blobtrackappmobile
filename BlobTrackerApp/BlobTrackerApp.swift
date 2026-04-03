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

struct BlobIntroView: View {
    @State private var showText = false
    @State private var fadeOut = false

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.pink.edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.8))
                        .frame(width: 150, height: 150)
                        .offset(y: 20)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 100, height: 100)
                        .offset(y: -10)

                    Circle()
                        .fill(Color.black)
                        .frame(width: 10, height: 10)
                        .offset(x: -20, y: -20)

                    Circle()
                        .fill(Color.black)
                        .frame(width: 10, height: 10)
                        .offset(x: 20, y: -20)

                    Path { path in
                        path.move(to: CGPoint(x: -30, y: 10))
                        path.addQuadCurve(to: CGPoint(x: 30, y: 10), control: CGPoint(x: 0, y: 40))
                    }
                    .stroke(Color.black, lineWidth: 3)
                    .offset(y: 10)
                }
                .scaleEffect(fadeOut ? 0.5 : 1.0)
                .opacity(fadeOut ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 1.0), value: fadeOut)

                if showText {
                    Text("L4 Suite")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .opacity(fadeOut ? 0.0 : 1.0)
                        .animation(.easeInOut(duration: 1.0).delay(0.5), value: fadeOut)
                }

                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showText = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                fadeOut = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                onComplete()
            }
        }
    }
}
