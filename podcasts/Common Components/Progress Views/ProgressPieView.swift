import UIKit

class ProgressPieView: ThemeableView {
    var progress: Double = 0 {
        didSet {
            endingAngle = CGFloat((progress * 360 * 0.01) - 90)
        }
    }

    var startingAngle: CGFloat = -90 {
        didSet {
            setNeedsDisplay()
        }
    }

    var endingAngle: CGFloat = -80 {
        didSet {
            setNeedsDisplay()
        }
    }

    private var progressGradientLayer: CAGradientLayer!
    private var progressShapeLayer: CAShapeLayer!
    private var borderCircleGradientLayer: CAGradientLayer!
    private var borderCircleLayer: CAShapeLayer!

    private var lineWidth: CGFloat = 3

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        progressGradientLayer = CAGradientLayer()
        progressGradientLayer.colors = [AppTheme.pcPlusGoldGradientLight().cgColor, AppTheme.pcPlusGoldGradientDark().cgColor]
        progressGradientLayer.locations = [0.0, 1.0]
        progressGradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        progressGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)

        progressShapeLayer = CAShapeLayer()
        progressShapeLayer.fillColor = UIColor.blue.cgColor
        progressShapeLayer.lineWidth = 1

        borderCircleGradientLayer = CAGradientLayer()
        borderCircleGradientLayer.colors = [AppTheme.pcPlusGoldGradientLight().cgColor, AppTheme.pcPlusGoldGradientDark().cgColor]
        borderCircleGradientLayer.locations = [0.0, 1.0]
        borderCircleGradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        borderCircleGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)

        borderCircleLayer = CAShapeLayer()
        borderCircleLayer.strokeColor = AppTheme.pcPlusGoldGradientDark().cgColor
        borderCircleLayer.fillColor = UIColor.clear.cgColor
        borderCircleLayer.lineWidth = 2

        borderCircleGradientLayer.frame = CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)
        borderCircleLayer.frame = CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)
        progressShapeLayer.frame = CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)
        progressGradientLayer.frame = CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)

        layer.addSublayer(borderCircleGradientLayer)
        layer.addSublayer(progressGradientLayer)
        borderCircleGradientLayer.mask = borderCircleLayer
        progressGradientLayer.mask = progressShapeLayer
    }

    override func draw(_ rect: CGRect) {
        let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
        let radius = (rect.width / 2) - 1.5

        borderCircleLayer.path = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: -90, endAngle: 270, clockwise: true).cgPath

        let filledSegment = UIBezierPath()
        filledSegment.move(to: centerPoint)
        filledSegment.addArc(withCenter: centerPoint, radius: radius, startAngle: startingAngle.degreesToRadians, endAngle: endingAngle.degreesToRadians, clockwise: true)
        filledSegment.close()
        progressShapeLayer.path = filledSegment.cgPath
    }
}
