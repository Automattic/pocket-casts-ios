import UIKit

class TimeSliderLayer: CALayer {
    @NSManaged var leftHalfRect: CGRect
    @NSManaged var rightHalfRect: CGRect
    @NSManaged var knobRect: CGRect
    @NSManaged var popupScale: CGFloat

    @NSManaged var leftColor: CGColor
    @NSManaged var rightColor: CGColor
    @NSManaged var circleColor: CGColor
    @NSManaged var popupColor: UIColor
    @NSManaged var popupTextColor: UIColor

    @NSManaged var popupValue: NSString
    @NSManaged var textStyle: NSParagraphStyle

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(layer: Any) {
        super.init(layer: layer)

        let otherLayer = layer as! TimeSliderLayer

        leftHalfRect = otherLayer.leftHalfRect
        rightHalfRect = otherLayer.rightHalfRect
        knobRect = otherLayer.knobRect
        popupScale = otherLayer.popupScale

        leftColor = otherLayer.leftColor
        rightColor = otherLayer.rightColor
        circleColor = otherLayer.circleColor
        popupColor = otherLayer.popupColor

        popupValue = otherLayer.popupValue
        textStyle = otherLayer.textStyle
    }

    override class func needsDisplay(forKey key: String) -> Bool {
        if key == "leftHalfRect" || key == "rightHalfRect" || key == "knobRect" || key == "shouldShowPopup" || key == "popupValue" || key == "popupScale" {
            return true
        }

        return super.needsDisplay(forKey: key)
    }

    override func action(forKey event: String) -> CAAction? {
        if event == "leftHalfRect" || event == "rightHalfRect" || event == "knobRect" || event == "popupScale" {
            return makeAnimationForKey(event)
        }

        return super.action(forKey: event)
    }

    private func makeAnimationForKey(_ key: String) -> CABasicAnimation {
        let anim = CABasicAnimation(keyPath: key)
        anim.fromValue = presentation()?.value(forKey: key)
        anim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        anim.duration = Constants.Animation.defaultAnimationTime

        return anim
    }

    override func draw(in ctx: CGContext) {
        guard !leftHalfRect.origin.y.isNaN else { return }

        // draw the left line
        UIGraphicsPushContext(ctx)
        ctx.setFillColor(leftColor)
        ctx.setStrokeColor(leftColor)
        let leftPath = UIBezierPath(roundedRect: leftHalfRect, cornerRadius: 2)
        leftPath.fill()

        // draw the right line
        ctx.setFillColor(rightColor)
        ctx.setStrokeColor(rightColor)
        let rightPath = UIBezierPath(roundedRect: rightHalfRect, cornerRadius: 2)
        rightPath.fill()

        // draw the knob
        ctx.addEllipse(in: knobRect)
        ctx.setFillColor(circleColor)
        ctx.fillPath()

        let baseHeight = 5 as CGFloat
        let progressCenter = knobRect.origin.x + (knobRect.width / 2)
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: progressCenter + 4.9, y: baseHeight + 30))
        bezierPath.addLine(to: CGPoint(x: progressCenter + 23.49, y: baseHeight + 30))
        bezierPath.addCurve(to: CGPoint(x: progressCenter + 38.5, y: baseHeight + 15), controlPoint1: CGPoint(x: progressCenter + 31.78, y: baseHeight + 30), controlPoint2: CGPoint(x: progressCenter + 38.5, y: baseHeight + 23.28))
        bezierPath.addCurve(to: CGPoint(x: progressCenter + 23.49, y: baseHeight), controlPoint1: CGPoint(x: progressCenter + 38.5, y: baseHeight + 6.71), controlPoint2: CGPoint(x: progressCenter + 31.78, y: baseHeight))
        bezierPath.addLine(to: CGPoint(x: progressCenter - 23.49, y: baseHeight))
        bezierPath.addCurve(to: CGPoint(x: progressCenter - 38.5, y: baseHeight + 15), controlPoint1: CGPoint(x: progressCenter - 31.78, y: baseHeight), controlPoint2: CGPoint(x: progressCenter - 38.5, y: baseHeight + 6.72))
        bezierPath.addCurve(to: CGPoint(x: progressCenter - 23.49, y: baseHeight + 30), controlPoint1: CGPoint(x: progressCenter - 38.5, y: baseHeight + 23.29), controlPoint2: CGPoint(x: progressCenter - 31.78, y: baseHeight + 30))
        bezierPath.addLine(to: CGPoint(x: progressCenter - 4.9, y: baseHeight + 30))
        bezierPath.addLine(to: CGPoint(x: progressCenter, y: baseHeight + 34.9))
        bezierPath.addLine(to: CGPoint(x: progressCenter + 4.9, y: baseHeight + 30))
        bezierPath.close()
        bezierPath.usesEvenOddFillRule = true

        if popupScale > 0.1 {
            popupColor.setFill()

            let originalBounds = bezierPath.bounds
            bezierPath.apply(CGAffineTransform(scaleX: 1.2, y: 1.2))
            bezierPath.apply(CGAffineTransform(translationX: -(bezierPath.bounds.origin.x - originalBounds.origin.x) - (bezierPath.bounds.size.width - originalBounds.size.width) * 0.5, y: -(bezierPath.bounds.origin.y - originalBounds.origin.y) - (bezierPath.bounds.size.height - originalBounds.size.height) * 0.5))
            bezierPath.apply(CGAffineTransform(translationX: 0, y: 5.0 - (popupScale * 5.0)))

            bezierPath.fill()
            popupValue.draw(in: CGRect(x: progressCenter - 40, y: baseHeight + 5 + (5.0 - (popupScale * 5.0)), width: 80, height: 40), withAttributes: [NSAttributedString.Key.font: UIFont.monospacedDigitSystemFont(ofSize: 16, weight: UIFont.Weight.regular), NSAttributedString.Key.foregroundColor: popupTextColor, NSAttributedString.Key.paragraphStyle: textStyle])
        }
    }
}
