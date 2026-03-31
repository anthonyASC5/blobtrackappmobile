import Foundation
import Metal

final class MetalRenderer {
    private let device = MTLCreateSystemDefaultDevice()

    var isSupported: Bool {
        device != nil
    }
}
