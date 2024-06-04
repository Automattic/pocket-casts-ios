import UIKit

class CircleView: UIView {

    var borderWidth: CGFloat = 2
    var borderColor = UIColor.white.withAlphaComponent(0.3) {
        didSet {
            setNeedsDisplay()
        }
    }

    var centerColor = UIColor.white.withAlphaComponent(0.3) {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        let radius = (rect.width / 2) - (borderWidth / 2)
        let path = UIBezierPath(arcCenter: CGPoint(x: rect.midX, y: rect.midY), radius: radius, startAngle: CGFloat(0).degreesToRadians, endAngle: CGFloat(360).degreesToRadians, clockwise: true)
        centerColor.setFill()
        path.fill()

        path.lineWidth = borderWidth
        borderColor.setStroke()
        path.stroke()

    }
}
