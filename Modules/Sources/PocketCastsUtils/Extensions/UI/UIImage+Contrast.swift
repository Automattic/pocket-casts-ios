import UIKit

extension UIImage {

    public var isDark: Bool {
        guard let cgImage = self.cgImage,
              let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return false }
        let length = CFDataGetLength(data)
        var totalLuminance = 0.0
        let bytesPerPixel = 4
        for i in stride(from: 0, to: length, by: bytesPerPixel) {
            let r = Double(ptr[i])
            let g = Double(ptr[i + 1])
            let b = Double(ptr[i + 2])
            totalLuminance += 0.299 * r + 0.587 * g + 0.114 * b
        }
        let pixelCount = length / bytesPerPixel
        let avgLuminance = totalLuminance / Double(pixelCount)
        return avgLuminance < 150
    }

    /// Returns a copy where each pixel's alpha is derived from inverted luminance:
    /// dark pixels become opaque, light pixels become transparent. Useful for tinting
    /// logos on white backgrounds when the source has no alpha channel.
    public func addingAlphaFromLuminance() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let r = Double(pixelData[i])
            let g = Double(pixelData[i + 1])
            let b = Double(pixelData[i + 2])
            let luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
            pixelData[i + 3] = UInt8((1.0 - luminance) * 255)
        }

        guard let outputCGImage = context.makeImage() else { return nil }
        return UIImage(cgImage: outputCGImage, scale: self.scale, orientation: self.imageOrientation)
    }
}
