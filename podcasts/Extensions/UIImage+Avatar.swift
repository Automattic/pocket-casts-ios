import UIKit

extension UIImage {
    /// Returns a circular icon scaled to the given point size, rendered at the screen's native pixel scale.
    func gravatarIcon(size: CGFloat) -> UIImage {
        let pointSize = CGSize(width: size, height: size)
        let sourceDiameter = min(self.size.width, self.size.height)
        let sourceOrigin = CGPoint(
            x: (sourceDiameter - self.size.width) / 2,
            y: (sourceDiameter - self.size.height) / 2
        )
        let scale = pointSize.width / sourceDiameter
        let drawRect = CGRect(
            x: sourceOrigin.x * scale,
            y: sourceOrigin.y * scale,
            width: self.size.width * scale,
            height: self.size.height * scale
        )

        let icon = UIGraphicsImageRenderer(size: pointSize).image { _ in
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: pointSize)).addClip()
            draw(in: drawRect)
        }
        return icon.withRenderingMode(.alwaysOriginal)
    }
}
