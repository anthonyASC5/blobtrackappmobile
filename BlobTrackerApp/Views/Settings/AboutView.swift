import SwiftUI  // Import for SwiftUI

struct AboutView: View {  // View for about page
    var body: some View {  // Body
        ScrollView {  // Scroll view
            VStack(alignment: .leading, spacing: 20) {  // VStack
                Text("About Blob Tracker")  // Title
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.pink)

                VStack(alignment: .leading, spacing: 10) {  // VStack for info
                    Text("Founder/Developer: A. L.")  // Founder
                        .font(.title2)
                        .foregroundColor(.primary)

                    Text("App Est. April 2026")  // Est date
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()  // Divider

                Text("This is my web app suite.")  // Description
                    .font(.body)
                    .foregroundColor(.primary)

                Link("Lall Suite", destination: URL(string: "https://anthonyasc5.github.io/lallsuite/")!)  // Link
                    .font(.headline)
                    .foregroundColor(.blue)

                Text("This is blob tracker online!")  // Description
                    .font(.body)
                    .foregroundColor(.primary)

                Link("Blobber Track", destination: URL(string: "https://anthonyasc5.github.io/blobbertrack/index.html")!)  // Link
                    .font(.headline)
                    .foregroundColor(.blue)

                Spacer()  // Spacer
            }
            .padding()  // Padding
        }
        .navigationTitle("About")  // Title
        .navigationBarTitleDisplayMode(.inline)  // Mode
        .background(Color.white.edgesIgnoringSafeArea(.all))  // Background
    }
}