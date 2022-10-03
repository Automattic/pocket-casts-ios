
import UIKit

class ProgressLineLayer: CALayer {
    @NSManaged var progressRect: CGRect
    @NSManaged var bufferRect: CGRect
    @NSManaged var bgRect: CGRect

    @NSManaged private var progressAnimationRect: CGRect

    @NSManaged var progressColor: CGColor
    @NSManaged var bufferingColor: CGColor

    private var animating = false

    var shouldAnimate = false {
        didSet {
            if shouldAnimate {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(layer: Any) {
        super.init(layer: layer)

        let otherLayer = layer as! ProgressLineLayer

        progressRect = otherLayer.progressRect
        bgRect = otherLayer.bgRect
        progressAnimationRect = otherLayer.progressAnimationRect

        progressColor = otherLayer.progressColor
        bufferingColor = otherLayer.bufferingColor
        shouldAnimate = otherLayer.shouldAnimate
    }

    override class func needsDisplay(forKey key: String) -> Bool {
        if key == "progressRect" || key == "bufferRect" || key == "progressAnimationRect" {
            return true
        }

        return super.needsDisplay(forKey: key)
    }

    override func action(forKey event: String) -> CAAction? {
        if event == "progressRect" || event == "bufferRect" {
            return makeAnimationForKey(event)
        }

        return super.action(forKey: event)
    }

    private func startAnimating() {
        if animating { return }

        animating = true
        progressAnimationRect = CGRect(x: 0, y: 0, width: animationLineWidth(), height: bgRect.size.height)

        let duration: CFTimeInterval = 1.0
        let progressStartX = progressRect.origin.x + progressRect.size.width

        let moveAnimation = CAKeyframeAnimation(keyPath: "progressAnimationRect.origin.x")
        moveAnimation.values = [
            progressStartX - animationLineWidth(),
            progressStartX,
            bgRect.size.width + animationLineWidth()
        ]
        moveAnimation.keyTimes = [0, 0.3, 1]
        moveAnimation.duration = duration

        let growAnimation = CAKeyframeAnimation(keyPath: "progressAnimationRect.size.width")
        growAnimation.values = [
            animationLineWidth() / 2,
            animationLineWidth(),
            1
        ]
        growAnimation.keyTimes = [0, 0.5, 1]
        growAnimation.duration = duration

        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [moveAnimation, growAnimation]
        animationGroup.duration = duration
        animationGroup.repeatCount = .greatestFiniteMagnitude

        add(animationGroup, forKey: "buferringAnimation")
    }

    private func stopAnimating() {
        animating = false

        removeAllAnimations()
    }

    private func animationLineWidth() -> CGFloat {
        bgRect.size.width / 3
    }

    private func makeAnimationForKey(_ key: String) -> CABasicAnimation {
        let anim = CABasicAnimation(keyPath: key)
        anim.fromValue = presentation()?.value(forKey: key)
        anim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        anim.duration = Constants.Animation.defaultAnimationTime

        return anim
    }

    override func draw(in ctx: CGContext) {
        UIGraphicsPushContext(ctx)

        // draw the buffering line
        if shouldAnimate {
            drawRoundedLine(rect: progressAnimationRect, color: bufferingColor, context: ctx)
        } else if bufferRect.size.width > 0 {
            drawRoundedLine(rect: bufferRect, color: bufferingColor, context: ctx)
        }

        // draw the progress line
        drawRoundedLine(rect: progressRect, color: progressColor, context: ctx)

        UIGraphicsPopContext()
    }

    private func drawRoundedLine(rect: CGRect, color: CGColor, context: CGContext) {
        context.setFillColor(color)
        context.setStrokeColor(color)
        UIBezierPath(roundedRect: rect, cornerRadius: 1).fill()
    }
}
