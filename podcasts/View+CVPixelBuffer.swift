import SwiftUI

enum CVPixelBufferError: Error {
    case failedToCreateBuffer(CVReturn)
    case failedToCreateContext
}

extension View {
    @MainActor @available(iOS 16.0, *)
    func pixelBuffer(size: CGSize, scale: CGFloat = 3) throws -> CVPixelBuffer {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)

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

        let renderer = ImageRenderer(content: self)
        renderer.scale = scale
        renderer.render { size, render in
            render(context)
        }

        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))

        return buffer
    }
}
