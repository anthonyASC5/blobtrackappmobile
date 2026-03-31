import CoreGraphics
import CoreImage
import CoreVideo
import UIKit

extension CVPixelBuffer {
    var width: Int { CVPixelBufferGetWidth(self) }
    var height: Int { CVPixelBufferGetHeight(self) }
    var size: CGSize { CGSize(width: width, height: height) }

    static func make(width: Int, height: Int, pixelFormat: OSType = kCVPixelFormatType_32BGRA) -> CVPixelBuffer? {
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            attributes,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess else { return nil }
        return pixelBuffer
    }

    static func make(from cgImage: CGImage) -> CVPixelBuffer? {
        guard let pixelBuffer = make(width: cgImage.width, height: cgImage.height) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard
            let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
            let context = CGContext(
                data: baseAddress,
                width: cgImage.width,
                height: cgImage.height,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
            )
        else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        return pixelBuffer
    }

    func cgImage(ciContext: CIContext = CIContext()) -> CGImage? {
        ciContext.createCGImage(CIImage(cvPixelBuffer: self), from: CGRect(origin: .zero, size: size))
    }
}
