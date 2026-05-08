import Foundation
import SwiftUI
import UIKit

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
    case neonBlue

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .white:
            "White"
        case .rainbow:
            "Rainbow"
        case .red:
            "Red"
        case .neonBlue:
            "Neon Blue"
        }
    }

    var uiColor: UIColor {
        switch self {
        case .white:
            return .white
        case .rainbow:
            return .systemPink
        case .red:
            return .red
        case .neonBlue:
            return UIColor(red: 0.0, green: 0.82, blue: 1.0, alpha: 1.0)
        }
    }
}

enum VisualEffectMode: String, CaseIterable, Codable, Identifiable, Equatable {
    case off
    case nightVision
    case lidarScan

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off:
            "Off"
        case .nightVision:
            "Night Vision"
        case .lidarScan:
            "LiDAR Scan"
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
    var sharpness: Double = 0.0
    var gamma: Double = 1.0
    var hueShift: Double = 0.0
    // Glow drives how wide and soft the blob box stroke blooms on screen.
    var glow: Double = 50
    var showBlobCircles: Bool = true
    var blackAndWhite: Bool = false

    var blobColorMode: BlobColorMode = .white
    var visualEffectMode: VisualEffectMode = .off

    init(
        detectionMode: DetectionMode = .binary,
        threshold: Double = 160,
        motionDifferenceThreshold: Double = 28,
        edgeThreshold: Double = 40,
        minimumBlobArea: Int = 20,
        maximumBlobArea: Int = 25_000,
        downsampleFactor: Int = 4,
        blurRadius: Int = 1,
        maxTrackingDistance: Double = 0.18,
        trailLength: Int = 10,
        showBoundingBoxes: Bool = true,
        showTrails: Bool = true,
        showDebugInfo: Bool = true,
        brightness: Double = 0.0,
        contrast: Double = 1.0,
        saturation: Double = 1.0,
        sharpness: Double = 0.0,
        gamma: Double = 1.0,
        hueShift: Double = 0.0,
        glow: Double = 50,
        showBlobCircles: Bool = true,
        blackAndWhite: Bool = false,
        blobColorMode: BlobColorMode = .white,
        visualEffectMode: VisualEffectMode = .off
    ) {
        self.detectionMode = detectionMode
        self.threshold = threshold
        self.motionDifferenceThreshold = motionDifferenceThreshold
        self.edgeThreshold = edgeThreshold
        self.minimumBlobArea = minimumBlobArea
        self.maximumBlobArea = maximumBlobArea
        self.downsampleFactor = downsampleFactor
        self.blurRadius = blurRadius
        self.maxTrackingDistance = maxTrackingDistance
        self.trailLength = trailLength
        self.showBoundingBoxes = showBoundingBoxes
        self.showTrails = showTrails
        self.showDebugInfo = showDebugInfo
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.sharpness = sharpness
        self.gamma = gamma
        self.hueShift = hueShift
        self.glow = glow
        self.showBlobCircles = showBlobCircles
        self.blackAndWhite = blackAndWhite
        self.blobColorMode = blobColorMode
        self.visualEffectMode = visualEffectMode
    }

    static let `default` = TrackingSettings()
}

extension TrackingSettings {
    private enum CodingKeys: String, CodingKey {
        case detectionMode
        case threshold
        case motionDifferenceThreshold
        case edgeThreshold
        case minimumBlobArea
        case maximumBlobArea
        case downsampleFactor
        case blurRadius
        case maxTrackingDistance
        case trailLength
        case showBoundingBoxes
        case showTrails
        case showDebugInfo
        case brightness
        case contrast
        case saturation
        case sharpness
        case gamma
        case hueShift
        case glow
        case showBlobCircles
        case blackAndWhite
        case blobColorMode
        case visualEffectMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.detectionMode = try container.decodeIfPresent(DetectionMode.self, forKey: .detectionMode) ?? .binary
        self.threshold = try container.decodeIfPresent(Double.self, forKey: .threshold) ?? 160
        self.motionDifferenceThreshold = try container.decodeIfPresent(Double.self, forKey: .motionDifferenceThreshold) ?? 28
        self.edgeThreshold = try container.decodeIfPresent(Double.self, forKey: .edgeThreshold) ?? 40
        self.minimumBlobArea = try container.decodeIfPresent(Int.self, forKey: .minimumBlobArea) ?? 20
        self.maximumBlobArea = try container.decodeIfPresent(Int.self, forKey: .maximumBlobArea) ?? 25_000
        self.downsampleFactor = try container.decodeIfPresent(Int.self, forKey: .downsampleFactor) ?? 4
        self.blurRadius = try container.decodeIfPresent(Int.self, forKey: .blurRadius) ?? 1
        self.maxTrackingDistance = try container.decodeIfPresent(Double.self, forKey: .maxTrackingDistance) ?? 0.18
        self.trailLength = try container.decodeIfPresent(Int.self, forKey: .trailLength) ?? 10
        self.showBoundingBoxes = try container.decodeIfPresent(Bool.self, forKey: .showBoundingBoxes) ?? true
        self.showTrails = try container.decodeIfPresent(Bool.self, forKey: .showTrails) ?? true
        self.showDebugInfo = try container.decodeIfPresent(Bool.self, forKey: .showDebugInfo) ?? true
        self.brightness = try container.decodeIfPresent(Double.self, forKey: .brightness) ?? 0.0
        self.contrast = try container.decodeIfPresent(Double.self, forKey: .contrast) ?? 1.0
        self.saturation = try container.decodeIfPresent(Double.self, forKey: .saturation) ?? 1.0
        self.sharpness = try container.decodeIfPresent(Double.self, forKey: .sharpness) ?? 0.0
        self.gamma = try container.decodeIfPresent(Double.self, forKey: .gamma) ?? 1.0
        self.hueShift = try container.decodeIfPresent(Double.self, forKey: .hueShift) ?? 0.0
        self.glow = try container.decodeIfPresent(Double.self, forKey: .glow) ?? 50
        self.showBlobCircles = try container.decodeIfPresent(Bool.self, forKey: .showBlobCircles) ?? true
        self.blackAndWhite = try container.decodeIfPresent(Bool.self, forKey: .blackAndWhite) ?? false
        self.blobColorMode = try container.decodeIfPresent(BlobColorMode.self, forKey: .blobColorMode) ?? .white
        self.visualEffectMode = try container.decodeIfPresent(VisualEffectMode.self, forKey: .visualEffectMode) ?? .off
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(detectionMode, forKey: .detectionMode)
        try container.encode(threshold, forKey: .threshold)
        try container.encode(motionDifferenceThreshold, forKey: .motionDifferenceThreshold)
        try container.encode(edgeThreshold, forKey: .edgeThreshold)
        try container.encode(minimumBlobArea, forKey: .minimumBlobArea)
        try container.encode(maximumBlobArea, forKey: .maximumBlobArea)
        try container.encode(downsampleFactor, forKey: .downsampleFactor)
        try container.encode(blurRadius, forKey: .blurRadius)
        try container.encode(maxTrackingDistance, forKey: .maxTrackingDistance)
        try container.encode(trailLength, forKey: .trailLength)
        try container.encode(showBoundingBoxes, forKey: .showBoundingBoxes)
        try container.encode(showTrails, forKey: .showTrails)
        try container.encode(showDebugInfo, forKey: .showDebugInfo)
        try container.encode(brightness, forKey: .brightness)
        try container.encode(contrast, forKey: .contrast)
        try container.encode(saturation, forKey: .saturation)
        try container.encode(sharpness, forKey: .sharpness)
        try container.encode(gamma, forKey: .gamma)
        try container.encode(hueShift, forKey: .hueShift)
        try container.encode(glow, forKey: .glow)
        try container.encode(showBlobCircles, forKey: .showBlobCircles)
        try container.encode(blackAndWhite, forKey: .blackAndWhite)
        try container.encode(blobColorMode, forKey: .blobColorMode)
        try container.encode(visualEffectMode, forKey: .visualEffectMode)
    }

    mutating func applyMotionDefaults() {
        blackAndWhite = true
        saturation = 0
        contrast = 1.85
        sharpness = 0.18
        gamma = 1.0
        hueShift = 0
        glow = 90
        blobColorMode = .white
        visualEffectMode = .off
        showBoundingBoxes = true
        showTrails = false
        showBlobCircles = true
    }
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
