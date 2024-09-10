import SwiftUI

enum CVPixelBufferError: Error {
    case failedToCreateBuffer(CVReturn)
    case failedToCreateContext
}

extension View {
    @MainActor
    func pixelBuffer(size: CGSize, scale: CGFloat, pool: CVPixelBufferPool? = nil) throws -> CVPixelBuffer {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?

        let status: CVReturn
        if let pool {
            status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        } else {
            status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        }

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw CVPixelBufferError.failedToCreateBuffer(status)
        }

        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            throw CVPixelBufferError.failedToCreateContext
        }

        if #available(iOS 16, *) {
            let renderer = ImageRenderer(content: self)
            renderer.isOpaque = true
            renderer.scale = scale

            let cgImage = renderer.cgImage!
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        } else {
            let image = self.snapshot()
            UIGraphicsPushContext(context)

            let flipTransform = CGAffineTransform(scaleX: 1, y: -1)
            let offsetTransform = CGAffineTransform(translationX: 0, y: -size.height)
            context.concatenate(flipTransform)
            context.concatenate(offsetTransform)

            image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            UIGraphicsPopContext()
        }

        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))

        return buffer
    }
}
