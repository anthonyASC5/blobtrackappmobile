import SwiftUI

struct AboutView: View {
    var body: some View {
        AboutScreen()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutScreen: View {
    @State private var avatarVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerPanel
                creatorPanel
                missionPanel
                linksPanel
            }
            .padding(16)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.03, blue: 0.04),
                    Color(red: 0.10, green: 0.07, blue: 0.05),
                    Color(red: 0.02, green: 0.02, blue: 0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            avatarVisible = false
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                avatarVisible = true
            }
        }
    }

    private var headerPanel: some View {
        RetroPanel {
            HStack(alignment: .top, spacing: 14) {
                PixelLogoMark()
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 8) {
                    Text("BLOB TRACKER")
                        .font(.system(.title3, design: .monospaced).weight(.black))
                    .foregroundStyle(Self.Palette.gold)
                        .tracking(2)

                    Text("Dark, pixel-styled about screen for the blob tracking app.")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(Self.Palette.text)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("This is a preview of the next visual direction.")
                        .font(.system(.caption, design: .monospaced).weight(.bold))
                        .foregroundStyle(Self.Palette.accent)
                }
            }
        }
    }

    private var creatorPanel: some View {
        RetroPanel(title: "Creator") {
            HStack(alignment: .center, spacing: 14) {
                CreatorAvatar(isVisible: avatarVisible)
                    .frame(width: 92, height: 92)

                VStack(alignment: .leading, spacing: 8) {
                    Text("A. L.")
                        .font(.system(.headline, design: .monospaced).weight(.black))
                    .foregroundStyle(Self.Palette.gold)

                    Text("Brown skin, black hair, and a retro pixel portrait that pops in on load.")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(Self.Palette.text)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Et cetera text for the creator section, kept intentionally small and stylized.")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Self.Palette.accent)
                }
            }
        }
    }

    private var missionPanel: some View {
        RetroPanel(title: "Mission") {
            VStack(alignment: .leading, spacing: 10) {
                missionRow("Make blob tools easy to use.")
                missionRow("Keep the UI bold, readable, and dark.")
                missionRow("Hold private experiments until they are tested.")
            }
        }
    }

    private var linksPanel: some View {
        RetroPanel(title: "Other Tools") {
            VStack(alignment: .leading, spacing: 10) {
                retroLink(
                    title: "Lall Suite",
                    subtitle: "Your broader suite of tools",
                    url: "https://anthonyasc5.github.io/lallsuite/"
                )
                retroLink(
                    title: "Blobber Track",
                    subtitle: "The web version of blob tracking",
                    url: "https://anthonyasc5.github.io/blobbertrack/index.html"
                )
            }
        }
    }

    private func missionRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle()
                .fill(Self.Palette.gold)
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            Text(text)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(Self.Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func retroLink(title: String, subtitle: String, url: String) -> some View {
        let destination = URL(string: url)!
        return Link(destination: destination) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title.uppercased())
                        .font(.system(.subheadline, design: .monospaced).weight(.bold))
                        .foregroundStyle(Self.Palette.gold)
                    Text(subtitle)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Self.Palette.text)
                }
                Spacer()
                Text(">")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(Self.Palette.accent)
            }
            .padding(.vertical, 2)
        }
    }
}

private struct RetroPanel<Content: View>: View {
    let title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title.uppercased())
                    .font(.system(.caption, design: .monospaced).weight(.black))
                    .foregroundStyle(AboutScreen.Palette.gold)
                    .tracking(2)
            }

            content
        }
        .padding(14)
        .background(AboutScreen.Palette.panel, in: Rectangle())
        .overlay(
            Rectangle()
                .strokeBorder(AboutScreen.Palette.gold, lineWidth: 2)
        )
        .overlay(alignment: .topLeading) {
            cornerPixels
                .offset(x: -1, y: -1)
        }
        .overlay(alignment: .bottomTrailing) {
            cornerPixels
                .offset(x: 1, y: 1)
        }
    }

    private var cornerPixels: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                AboutScreen.Palette.gold.frame(width: 8, height: 4)
                Color.clear.frame(width: 4, height: 4)
            }
            HStack(spacing: 0) {
                AboutScreen.Palette.gold.frame(width: 4, height: 8)
                Color.clear.frame(width: 8, height: 8)
            }
        }
    }
}

private struct PixelLogoMark: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear.frame(width: 8, height: 8)
                AboutScreen.Palette.gold.frame(width: 8, height: 8)
                Color.clear.frame(width: 8, height: 8)
                AboutScreen.Palette.gold.frame(width: 8, height: 8)
            }
            HStack(spacing: 0) {
                AboutScreen.Palette.gold.frame(width: 8, height: 8)
                AboutScreen.Palette.gold.frame(width: 8, height: 8)
                AboutScreen.Palette.gold.frame(width: 8, height: 8)
                AboutScreen.Palette.gold.frame(width: 8, height: 8)
            }
            HStack(spacing: 0) {
                AboutScreen.Palette.gold.frame(width: 8, height: 8)
                Color.clear.frame(width: 8, height: 8)
                Color.clear.frame(width: 8, height: 8)
                AboutScreen.Palette.gold.frame(width: 8, height: 8)
            }
            HStack(spacing: 0) {
                AboutScreen.Palette.gold.frame(width: 8, height: 8)
                Color.clear.frame(width: 8, height: 8)
                Color.clear.frame(width: 8, height: 8)
                AboutScreen.Palette.gold.frame(width: 8, height: 8)
            }
        }
        .background(Color.black, in: Rectangle())
        .overlay(
            Rectangle()
                .strokeBorder(AboutScreen.Palette.gold, lineWidth: 2)
        )
    }
}

private struct CreatorAvatar: View {
    let isVisible: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear.frame(width: 10, height: 10)
                Color.clear.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                Color.clear.frame(width: 10, height: 10)
                Color.clear.frame(width: 10, height: 10)
            }
            HStack(spacing: 0) {
                Color.clear.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                Color.clear.frame(width: 10, height: 10)
            }
            HStack(spacing: 0) {
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
            }
            HStack(spacing: 0) {
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
            }
            HStack(spacing: 0) {
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.hair.frame(width: 10, height: 10)
            }
            HStack(spacing: 0) {
                AboutScreen.Palette.shirt.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.shirt.frame(width: 10, height: 10)
            }
            HStack(spacing: 0) {
                AboutScreen.Palette.shirt.frame(width: 10, height: 10)
                AboutScreen.Palette.shirt.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.shirt.frame(width: 10, height: 10)
                AboutScreen.Palette.shirt.frame(width: 10, height: 10)
            }
            HStack(spacing: 0) {
                AboutScreen.Palette.shirt.frame(width: 10, height: 10)
                AboutScreen.Palette.shirt.frame(width: 10, height: 10)
                AboutScreen.Palette.shirt.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.skin.frame(width: 10, height: 10)
                AboutScreen.Palette.shirt.frame(width: 10, height: 10)
                AboutScreen.Palette.shirt.frame(width: 10, height: 10)
                AboutScreen.Palette.shirt.frame(width: 10, height: 10)
            }
        }
        .background(Color.black, in: Rectangle())
        .overlay(
            Rectangle()
                .strokeBorder(AboutScreen.Palette.gold, lineWidth: 2)
        )
        .scaleEffect(isVisible ? 1 : 0.6)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: isVisible)
    }
}

private extension AboutScreen {
    enum Palette {
        static let panel = Color(red: 0.08, green: 0.07, blue: 0.09)
        static let gold = Color(red: 0.98, green: 0.75, blue: 0.22)
        static let text = Color(red: 0.88, green: 0.84, blue: 0.72)
        static let accent = Color(red: 0.77, green: 0.64, blue: 0.45)

        static let hair = Color(red: 0.08, green: 0.05, blue: 0.04)
        static let skin = Color(red: 0.62, green: 0.43, blue: 0.25)
        static let shirt = Color(red: 0.18, green: 0.2, blue: 0.3)
    }
}
