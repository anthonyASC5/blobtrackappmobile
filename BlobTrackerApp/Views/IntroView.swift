import SwiftUI  // Import for SwiftUI

struct BlobIntroView: View {  // View for intro screen
    @State private var showText = false  // State for showing text
    @State private var fadeOut = false  // State for fade out

    var onComplete: () -> Void  // Completion handler

    var body: some View {  // Body
        ZStack {  // ZStack for layout
            Color.pink.edgesIgnoringSafeArea(.all)  // Pink background

            VStack {  // VStack
                Spacer()  // Spacer

                // Simple slime shape, since can't use image
                ZStack {  // ZStack for slime
                    Circle()  // Body
                        .fill(Color.pink.opacity(0.8))
                        .frame(width: 150, height: 150)
                        .offset(y: 20)

                    Circle()  // Head
                        .fill(Color.white)
                        .frame(width: 100, height: 100)
                        .offset(y: -10)

                    // Eyes
                    Circle()  // Left eye
                        .fill(Color.black)
                        .frame(width: 10, height: 10)
                        .offset(x: -20, y: -20)

                    Circle()  // Right eye
                        .fill(Color.black)
                        .frame(width: 10, height: 10)
                        .offset(x: 20, y: -20)

                    // Smile
                    Path { path in  // Path for smile
                        path.move(to: CGPoint(x: -30, y: 10))
                        path.addQuadCurve(to: CGPoint(x: 30, y: 10), control: CGPoint(x: 0, y: 40))
                    }
                    .stroke(Color.black, lineWidth: 3)
                    .offset(y: 10)
                }
                .scaleEffect(fadeOut ? 0.5 : 1.0)  // Scale effect
                .opacity(fadeOut ? 0.0 : 1.0)  // Opacity
                .animation(.easeInOut(duration: 1.0), value: fadeOut)  // Animation

                if showText {  // Conditional for text
                    Text("L4 Suite")  // Text
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .opacity(fadeOut ? 0.0 : 1.0)  // Opacity
                        .animation(.easeInOut(duration: 1.0).delay(0.5), value: fadeOut)  // Animation
                }

                Spacer()  // Spacer
            }
        }
        .onAppear {  // On appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {  // Delay
                showText = true  // Show text
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {  // Delay
                fadeOut = true  // Fade out
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {  // Delay
                onComplete()  // Complete
            }
        }
    }
}