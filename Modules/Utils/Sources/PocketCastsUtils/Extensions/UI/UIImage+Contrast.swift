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
}
