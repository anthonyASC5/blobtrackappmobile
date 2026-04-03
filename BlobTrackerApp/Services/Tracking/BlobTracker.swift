import CoreGraphics  // Import for CGPoint and CGVector
import Foundation  // Import for basic Foundation types

final class BlobTracker {  // Class responsible for tracking blobs across frames
    private struct TrackState {  // Internal struct to hold track information
        var id: UUID  // Unique identifier for the track
        var position: CGPoint  // Current position of the blob
        var trail: [CGPoint]  // Limited to previous and current position for single line
        var missedFrames: Int  // Number of frames the blob was not detected
    }

    private var tracks: [TrackState] = []  // Array of current tracks

    func reset() {  // Resets all tracks, clearing the tracking state
        tracks.removeAll()  // Remove all existing tracks
    }

    func track(detections: [DetectedBlob], settings: TrackingSettings) -> [Blob] {  // Main tracking function
        guard !detections.isEmpty else {  // Check if there are any detections
            // No detections, increment missed frames and filter out old tracks
            tracks = tracks  // Update tracks for missed detections
                .map { TrackState(id: $0.id, position: $0.position, trail: $0.trail, missedFrames: $0.missedFrames + 1) }
                .filter { $0.missedFrames <= 2 }  // Keep tracks with few missed frames
            return []  // Return empty array if no detections
        }

        var unmatchedTrackIndices = Set(tracks.indices)  // Set of indices of unmatched tracks
        var updatedTracks: [TrackState] = []  // Array for updated tracks
        var blobs: [Blob] = []  // Array of blobs to return

        for detection in detections {  // Loop through each detection
            // Find nearest unmatched track
            let match = unmatchedTrackIndices  // Calculate distances to unmatched tracks
                .map { index in
                    (index, MathUtils.distance(from: tracks[index].position, to: detection.centroid))
                }
                .min { $0.1 < $1.1 }  // Find the minimum distance match

            let matchedTrack: TrackState?  // Variable for matched track
            if let match, match.1 <= CGFloat(settings.maxTrackingDistance) {  // Check if match is within distance
                unmatchedTrackIndices.remove(match.0)  // Remove matched index
                matchedTrack = tracks[match.0]  // Get the matched track
            } else {
                matchedTrack = nil  // No match found
            }

            let id = matchedTrack?.id ?? UUID()  // Use existing ID or create new
            let previousPosition = matchedTrack?.position ?? detection.centroid  // Get previous position
            // Trail is only previous and current for straight line
            let trail = [previousPosition, detection.centroid]  // Create trail array

            let velocity = CGVector(  // Calculate velocity vector
                dx: detection.centroid.x - previousPosition.x,
                dy: detection.centroid.y - previousPosition.y
            )

            let size = max(detection.boundingBox.width, detection.boundingBox.height)  // Calculate blob size

            blobs.append(  // Add blob to results array
                Blob(
                    id: id,
                    position: detection.centroid,
                    size: size,
                    velocity: velocity,
                    boundingBox: detection.boundingBox,
                    trail: trail
                )
            )

            updatedTracks.append(  // Add updated track to array
                TrackState(
                    id: id,
                    position: detection.centroid,
                    trail: trail,
                    missedFrames: 0
                )
            )
        }

        // Clear unmatched trails each frame, no preservation
        tracks = updatedTracks  // Update tracks to only updated ones
        return blobs  // Return the list of blobs
    }
}
