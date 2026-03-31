import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct VideoPickerView: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = .videos
        configuration.preferredAssetRepresentationMode = .current

        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: VideoPickerView

        init(_ parent: VideoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                parent.onCancel()
                return
            }

            guard provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else {
                parent.onCancel()
                return
            }

            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                guard let url else {
                    DispatchQueue.main.async {
                        self.parent.onCancel()
                    }
                    return
                }

                let temporaryURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(url.pathExtension.isEmpty ? "mov" : url.pathExtension)

                do {
                    if FileManager.default.fileExists(atPath: temporaryURL.path) {
                        try FileManager.default.removeItem(at: temporaryURL)
                    }

                    try FileManager.default.copyItem(at: url, to: temporaryURL)
                    DispatchQueue.main.async {
                        self.parent.onPick(temporaryURL)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.parent.onCancel()
                    }
                }
            }
        }
    }
}
