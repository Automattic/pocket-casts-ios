import UIKit

class AngularActivityIndicator: UIView, CAAnimationDelegate {
    var color = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5) {
        didSet {
            shapeLayer.strokeColor = color.cgColor
        }
    }

    var animating = false
    var hidesWhenStopped = true

    private var duration = 1.0 as CGFloat
    private var contentView = UIView()
    private var shapeLayer = CAShapeLayer()

    init(size: CGSize, lineWidth: CGFloat, duration: CGFloat) {
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        super.init(frame: frame)

        setup(frame, duration: duration, lineWidth: lineWidth)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup(bounds, duration: 1.0, lineWidth: 2.0)
    }

    private func setup(_ frame: CGRect, duration: CGFloat, lineWidth: CGFloat) {
        contentView.frame = frame

        shapeLayer.frame = frame
        shapeLayer.lineWidth = lineWidth
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color.cgColor

        let radius = frame.width / 2
        shapeLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2 * radius, height: 2 * radius), cornerRadius: radius).cgPath
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        shapeLayer.isHidden = true

        addSubview(contentView)
        contentView.layer.insertSublayer(shapeLayer, at: 0)

        self.duration = duration
    }

    func startAnimating() {
        if animating { return }

        animating = true

        let cfDuration = CFTimeInterval(duration)

        let inAnimation = CAKeyframeAnimation(keyPath: "strokeEnd")
        inAnimation.duration = cfDuration
        inAnimation.values = [0, 1]

        let outAnimation = CAKeyframeAnimation(keyPath: "strokeStart")
        outAnimation.duration = cfDuration
        outAnimation.values = [0, 0.8, 1]
        outAnimation.beginTime = cfDuration / 1.5

        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [inAnimation, outAnimation]
        groupAnimation.duration = cfDuration + outAnimation.beginTime
        groupAnimation.repeatCount = Float.infinity
        groupAnimation.delegate = self

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = (Double.pi * 2)
        rotationAnimation.duration = cfDuration * 1.5
        rotationAnimation.repeatCount = Float.infinity

        shapeLayer.add(rotationAnimation, forKey: nil)
        shapeLayer.add(groupAnimation, forKey: nil)

        shapeLayer.isHidden = false
    }

    func stopAnimating() {
        UIView.animate(withDuration: 0.5, animations: { () in
            self.contentView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.contentView.alpha = 0.0
        })

        UIView.animate(withDuration: 0.5, animations: { () in
            self.contentView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.contentView.alpha = 0.0
        }, completion: { _ in
            self.animating = false

            /// ...and reset back
            self.contentView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.contentView.alpha = 1.0

            self.shapeLayer.isHidden = self.hidesWhenStopped
            self.shapeLayer.removeAllAnimations()
        })
    }
}
