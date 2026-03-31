import CoreGraphics
import Foundation

struct Blob: Identifiable, Equatable {
    let id: UUID
    var position: CGPoint
    var size: CGFloat
    var velocity: CGVector
    var boundingBox: CGRect
    var trail: [CGPoint]

    init(
        id: UUID = UUID(),
        position: CGPoint,
        size: CGFloat,
        velocity: CGVector = .zero,
        boundingBox: CGRect,
        trail: [CGPoint] = []
    ) {
        self.id = id
        self.position = position
        self.size = size
        self.velocity = velocity
        self.boundingBox = boundingBox
        self.trail = trail
    }
}
