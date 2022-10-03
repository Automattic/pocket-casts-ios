import UIKit

class ProgressCircleView: UIView {
    var startingAngle: CGFloat = -90 {
        didSet {
            setNeedsDisplay()
        }
    }

    var endingAngle: CGFloat = 270 {
        didSet {
            setNeedsDisplay()
        }
    }

    var lineWidth: CGFloat = 2
    var lineColor = UIColor.white.withAlphaComponent(0.3)

    override func draw(_ rect: CGRect) {
        let radius = (rect.width / 2) - 1
        let path = UIBezierPath(arcCenter: CGPoint(x: rect.midX, y: rect.midY), radius: radius, startAngle: startingAngle.degreesToRadians, endAngle: endingAngle.degreesToRadians, clockwise: true)
        path.lineWidth = lineWidth
        lineColor.setStroke()
        path.stroke()
    }
}
