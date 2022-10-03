import Foundation

class LenticularOverlayView: UIView {
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let height: CGFloat = 2

        let color1 = UIColor(hex: "#119B00").withAlphaComponent(0.2)
        let color2 = UIColor.clear

        let patternSize = CGSize(width: height * 2, height: height)

        UIGraphicsBeginImageContextWithOptions(patternSize, false, 0.0)

        let color1Path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: height, height: height))
        color1.setFill()
        color1Path.fill()

        let color2Path = UIBezierPath(rect: CGRect(x: height, y: 0, width: height, height: height))
        color2.setFill()
        color2Path.fill()

        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return }
        UIGraphicsEndImageContext()

        let color = UIColor(patternImage: image)
        color.setFill()
        context.fill(rect)
    }
}
