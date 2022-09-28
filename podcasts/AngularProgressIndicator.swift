import UIKit

class AngularProgressIndicator: UIView {
    var color = UIColor(red: 100 / 255, green: 100 / 255, blue: 100 / 255, alpha: 1.0) {
        didSet {
            shapeLayer.strokeColor = color.cgColor
        }
    }

    var progress = 0 as CGFloat {
        didSet {
            shapeLayer.strokeEnd = progress
        }
    }

    private var contentView = UIView()
    private var shapeLayer = CAShapeLayer()

    init(size: CGSize, lineWidth: CGFloat) {
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        super.init(frame: frame)

        setup(frame, lineWidth: lineWidth)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup(bounds, lineWidth: 2.0)
    }

    private func setup(_ frame: CGRect, lineWidth: CGFloat) {
        contentView.frame = frame
        backgroundColor = UIColor.clear

        shapeLayer.frame = frame
        shapeLayer.lineWidth = lineWidth
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.strokeStart = 0
        shapeLayer.strokeEnd = 0

        let radius = frame.width / 2
        shapeLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2 * radius, height: 2 * radius), cornerRadius: radius).cgPath
        shapeLayer.lineCap = CAShapeLayerLineCap.round

        addSubview(contentView)
        contentView.layer.insertSublayer(shapeLayer, at: 0)
    }
}
