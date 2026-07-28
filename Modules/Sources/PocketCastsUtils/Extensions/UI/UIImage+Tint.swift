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


    /// Resize the image using the aspect ration to the given size
    /// Specify the displayScale to set the UIImage.scale factor of the image
    func resizeProportionally(to newSize: CGSize, displayScale: CGFloat = 0) -> UIImage {
        let widthRatio = newSize.width / size.width
        let heightRatio = newSize.height / size.height

        let scaleFactor = min(widthRatio, heightRatio)
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        // If it fails, just return the same image
        guard let resized = resized(to: scaledImageSize, displayScale: displayScale) else {
            return self
        }

        return resized
    }

    func resized(to newSize: CGSize, displayScale: CGFloat = 0) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
