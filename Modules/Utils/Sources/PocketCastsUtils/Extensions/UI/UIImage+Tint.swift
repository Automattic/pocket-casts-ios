import UIKit

public extension UIImage {
    func tintedImage(_ color: UIColor) -> UIImage? {
        // lets tint the icon - assumes your icons are black
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext(), let coreGraphicsImage = cgImage else { return nil }

        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)

        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        // draw alpha-mask
        context.setBlendMode(.normal)
        context.draw(coreGraphicsImage, in: rect)

        // draw tint color, preserving alpha values of original image
        context.setBlendMode(.sourceIn)
        color.setFill()
        context.fill(rect)

        let coloredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return coloredImage
    }

    func resized(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
