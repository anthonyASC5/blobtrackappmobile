import Foundation
import SwiftUI

enum DetectionMode: String, CaseIterable, Codable, Identifiable {
    case binary
    case motion
    case edge

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .binary:
            "Binary"
        case .motion:
            "Motion"
        case .edge:
            "Edge"
        }
    }
}

enum BlobColorMode: String, CaseIterable, Codable, Identifiable {
    case white
    case rainbow
    case red

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .white:
            "White"
        case .rainbow:
            "Rainbow"
        case .red:
            "Red"
        }
    }
}

struct TrackingSettings: Codable, Equatable {
    var detectionMode: DetectionMode = .binary
    var threshold: Double = 160
    var motionDifferenceThreshold: Double = 28
    var edgeThreshold: Double = 40
    var minimumBlobArea: Int = 20
    var maximumBlobArea: Int = 25_000
    var downsampleFactor: Int = 4
    var blurRadius: Int = 1
    var maxTrackingDistance: Double = 0.18
    var trailLength: Int = 10
    var showBoundingBoxes: Bool = true
    var showTrails: Bool = true
    var showDebugInfo: Bool = true

    var brightness: Double = 0.0
    var contrast: Double = 1.0
    var saturation: Double = 1.0
    var blackAndWhite: Bool = false

    var blobColorMode: BlobColorMode = .rainbow

    static let `default` = TrackingSettings()
}

struct TrackingPreset: Identifiable, Codable, Equatable {
    let name: String
    let settings: TrackingSettings

    var id: String { name }
}

@MainActor
final class TrackingSettingsStore: ObservableObject {
    @Published var settings: TrackingSettings
    let presets: [TrackingPreset]

    init(bundle: Bundle = .main) {
        let loadedPresets = Self.loadPresets(from: bundle)
        presets = loadedPresets
        settings = loadedPresets.first?.settings ?? .default
    }

    func apply(_ preset: TrackingPreset) {
        settings = preset.settings
    }

    func reset() {
        settings = presets.first?.settings ?? .default
    }

    private static func loadPresets(from bundle: Bundle) -> [TrackingPreset] {
        guard
            let url = bundle.url(forResource: "Presets", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let presets = try? JSONDecoder().decode([TrackingPreset].self, from: data),
            !presets.isEmpty
        else {
            return [
                TrackingPreset(name: "Balanced", settings: .default),
                TrackingPreset(
                    name: "Motion",
                    settings: TrackingSettings(
                        detectionMode: .motion,
                        threshold: 160,
                        motionDifferenceThreshold: 24,
                        edgeThreshold: 40,
                        minimumBlobArea: 16,
                        maximumBlobArea: 18_000,
                        downsampleFactor: 4,
                        blurRadius: 1,
                        maxTrackingDistance: 0.16,
                        trailLength: 12,
                        showBoundingBoxes: true,
                        showTrails: true,
                        showDebugInfo: true
                    )
                ),
                TrackingPreset(
                    name: "Edges",
                    settings: TrackingSettings(
                        detectionMode: .edge,
                        threshold: 160,
                        motionDifferenceThreshold: 28,
                        edgeThreshold: 30,
                        minimumBlobArea: 12,
                        maximumBlobArea: 12_000,
                        downsampleFactor: 3,
                        blurRadius: 0,
                        maxTrackingDistance: 0.14,
                        trailLength: 8,
                        showBoundingBoxes: true,
                        showTrails: false,
                        showDebugInfo: true
                    )
                )
            ]
        }

        return presets
    }
}
