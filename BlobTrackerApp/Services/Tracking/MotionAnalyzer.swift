import Foundation

enum MotionAnalyzer {
    static func motionMask(
        current: GrayscaleImage,
        previous: GrayscaleImage,
        threshold: UInt8
    ) -> BinaryImage {
        let difference = ImageProcessing.difference(current: current, previous: previous)
        return ImageProcessing.threshold(difference, level: threshold)
    }
}
