import SwiftUI

struct BlobIntroView: View {
    @State private var floating = false
    @State private var showText = false
    @State private var fadeOut = false

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white,
                    Color(red: 1.0, green: 0.96, blue: 0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                BlobLogoMarkView(floating: floating)
                    .frame(width: 280, height: 320)
                    .scaleEffect(fadeOut ? 0.92 : (floating ? 1.02 : 0.98))
                    .offset(y: floating ? -10 : 10)
                    .opacity(fadeOut ? 0.0 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: floating)
                    .animation(.easeInOut(duration: 0.7), value: fadeOut)

                if showText {
                    VStack(spacing: 6) {
                        Text("L4")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundStyle(Color(red: 0.46, green: 0.12, blue: 0.34))
                        Text("Suite")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("Everything's Suite")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.pink)
                            .tracking(1.2)
                    }
                    .opacity(fadeOut ? 0.0 : 1.0)
                    .offset(y: fadeOut ? 8 : 0)
                    .animation(.easeInOut(duration: 0.7), value: fadeOut)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            floating = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                showText = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                fadeOut = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
                onComplete()
            }
        }
    }
}

struct BlobLogoMarkView: View {
    let floating: Bool

    var body: some View {
        ZStack {
            BlobMarkShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.72, blue: 0.84),
                            Color(red: 0.97, green: 0.43, blue: 0.66)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    BlobMarkShape()
                        .stroke(Color(red: 1.0, green: 0.64, blue: 0.76), lineWidth: 3)
                )
                .shadow(color: Color.pink.opacity(0.18), radius: 16, y: 10)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.white)
                        .frame(width: 38, height: 38)
                        .offset(x: -66, y: 32)
                        .opacity(0.95)
                }

            Circle()
                .fill(Color(red: 0.36, green: 0.11, blue: 0.32))
                .frame(width: 44, height: 74)
                .offset(x: -58, y: -36)
                .overlay {
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .offset(x: -7, y: -16)
                }

            Circle()
                .fill(Color(red: 0.36, green: 0.11, blue: 0.32))
                .frame(width: 44, height: 74)
                .offset(x: 62, y: -18)
                .overlay {
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .offset(x: -7, y: -16)
                }

            Path { path in
                path.move(to: CGPoint(x: -48, y: 18))
                path.addQuadCurve(to: CGPoint(x: 48, y: 18), control: CGPoint(x: 0, y: 96))
                path.addQuadCurve(to: CGPoint(x: -48, y: 18), control: CGPoint(x: 0, y: 44))
            }
            .fill(Color(red: 0.40, green: 0.11, blue: 0.34))
            .frame(width: 170, height: 160)
            .offset(y: 16)
            .overlay {
                Ellipse()
                    .fill(Color(red: 0.80, green: 0.33, blue: 0.59).opacity(0.65))
                    .frame(width: 92, height: 54)
                    .offset(y: 52)
            }

            if floating {
                Circle()
                    .stroke(Color.white.opacity(0.22), lineWidth: 2)
                    .frame(width: 240, height: 240)
                    .scaleEffect(1.0 + 0.05)
                    .opacity(0.7)
                    .offset(y: 6)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: floating)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BlobMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let rx = rect.width * 0.42
        let ry = rect.height * 0.40
        let waves: [(CGFloat, CGFloat, CGFloat)] = [
            (3, 0.10, 0.0),
            (5, 0.05, 0.8),
            (8, 0.03, -0.4)
        ]

        func radiusScale(_ angle: CGFloat) -> CGFloat {
            var scale: CGFloat = 1.0
            for wave in waves {
                scale += wave.1 * sin(wave.0 * angle + wave.2)
            }
            return scale
        }

        var path = Path()
        let points = 120
        for index in 0...points {
            let t = CGFloat(index) / CGFloat(points)
            let angle = t * 2 * .pi
            let scale = radiusScale(angle)
            let x = center.x + cos(angle) * rx * scale
            let y = center.y + sin(angle) * ry * scale
            let point = CGPoint(x: x, y: y)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
