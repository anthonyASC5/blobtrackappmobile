import CoreGraphics
import Foundation

final class BlobTracker {
    private struct TrackState {
        var id: UUID
        var position: CGPoint
        var trail: [CGPoint]
        var missedFrames: Int
    }

    private var tracks: [TrackState] = []

    func reset() {
        tracks.removeAll()
    }

    func track(detections: [DetectedBlob], settings: TrackingSettings) -> [Blob] {
        guard !detections.isEmpty else {
            tracks = tracks
                .map { TrackState(id: $0.id, position: $0.position, trail: $0.trail, missedFrames: $0.missedFrames + 1) }
                .filter { $0.missedFrames <= 2 }
            return []
        }

        var unmatchedTrackIndices = Set(tracks.indices)
        var updatedTracks: [TrackState] = []
        var blobs: [Blob] = []

        for detection in detections {
            let match = unmatchedTrackIndices
                .map { index in
                    (index, MathUtils.distance(from: tracks[index].position, to: detection.centroid))
                }
                .min { $0.1 < $1.1 }

            let matchedTrack: TrackState?
            if let match, match.1 <= CGFloat(settings.maxTrackingDistance) {
                unmatchedTrackIndices.remove(match.0)
                matchedTrack = tracks[match.0]
            } else {
                matchedTrack = nil
            }

            let id = matchedTrack?.id ?? UUID()
            let previousPosition = matchedTrack?.position ?? detection.centroid
            var trail = matchedTrack?.trail ?? []
            trail.append(detection.centroid)
            trail = Array(trail.suffix(max(settings.trailLength, 1)))

            let velocity = CGVector(
                dx: detection.centroid.x - previousPosition.x,
                dy: detection.centroid.y - previousPosition.y
            )

            let size = max(detection.boundingBox.width, detection.boundingBox.height)

            blobs.append(
                Blob(
                    id: id,
                    position: detection.centroid,
                    size: size,
                    velocity: velocity,
                    boundingBox: detection.boundingBox,
                    trail: trail
                )
            )

            updatedTracks.append(
                TrackState(
                    id: id,
                    position: detection.centroid,
                    trail: trail,
                    missedFrames: 0
                )
            )
        }

        let preservedTracks = unmatchedTrackIndices.compactMap { index -> TrackState? in
            let track = tracks[index]
            let updatedTrack = TrackState(
                id: track.id,
                position: track.position,
                trail: track.trail,
                missedFrames: track.missedFrames + 1
            )
            return updatedTrack.missedFrames <= 2 ? updatedTrack : nil
        }

        tracks = updatedTracks + preservedTracks
        return blobs
    }
}
