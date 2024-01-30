import PocketCastsUtils
import UIKit

class TimeSlider: UIView {
    var sidePadding = 20 as CGFloat

    // MARK: - Public properties

    var totalDuration: TimeInterval = 1800
    var currentTime: TimeInterval = 900 {
        didSet {
            let animated = !draggingKnob && (abs(oldValue - currentTime) > 8)
            recalculatePositionRects(animated)
        }
    }

    weak var delegate: TimeSliderDelegate?

    var leftColor = UIColor.white {
        didSet {
            timeLayer().leftColor = leftColor.cgColor
        }
    }

    var rightColor = UIColor(white: 1.0, alpha: 0.20)
    var circleColor = UIColor.white {
        didSet {
            timeLayer().circleColor = circleColor.cgColor
        }
    }

    var popupColor = UIColor(white: 1.0, alpha: 0.25)
    var popupTextColor = UIColor.white

    var topOffset = 20 as CGFloat
    var shouldPopupOnDrag = true

    // MARK: - private properties

    private var draggingKnob = false
    private let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle

    // MARK: - public methods

    func isScrubbing() -> Bool {
        draggingKnob
    }

    override var accessibilityValue: String? {
        get {
            let current = currentTime.accessibilityValue()
            let total = totalDuration.accessibilityValue()
            return L10n.accessibilityPlaybackProgress(current, total)
        }
        set {
            // No-op
        }
    }

    override func accessibilityIncrement() {
        currentTime += totalDuration.skipLength
        delegate?.sliderDidSlide(to: currentTime)
    }

    override func accessibilityDecrement() {
        currentTime -= totalDuration.skipLength
        delegate?.sliderDidSlide(to: currentTime)
    }

    // MARK: - View Methods

    override func awakeFromNib() {
        let tLayer = timeLayer()
        tLayer.contentsScale = UIScreen.main.scale
        tLayer.leftColor = leftColor.cgColor
        tLayer.rightColor = rightColor.cgColor
        tLayer.circleColor = circleColor.cgColor
        tLayer.popupColor = popupColor
        tLayer.popupTextColor = popupTextColor
        tLayer.popupScale = 0
        textStyle.alignment = NSTextAlignment.center
        tLayer.textStyle = textStyle

        backgroundColor = UIColor.clear
        tLayer.backgroundColor = UIColor.clear.cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        recalculatePositionRects(false)
    }

    override func prepareForInterfaceBuilder() {
        draggingKnob = true
        timeLayer().popupScale = 1.0
        timeLayer().popupValue = "12:42"
        awakeFromNib()
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let firstTouch = touches.first {
            let touchPoint = firstTouch.location(in: self)
            let slightlyBiggerKnobRect = timeLayer().knobRect.insetBy(dx: -20, dy: -20)
            if slightlyBiggerKnobRect.contains(touchPoint) {
                draggingKnob = true
                if shouldPopupOnDrag {
                    timeLayer().popupScale = 1.0
                    timeLayer().popupValue = TimeFormatter.shared.playTimeFormat(time: currentTime) as NSString
                }
                recalculatePositionRects(true)

                if let delegate = delegate {
                    delegate.sliderDidBeginSliding()
                }
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if draggingKnob {
            draggingKnob = false
            if shouldPopupOnDrag { timeLayer().popupScale = 0 }
            recalculatePositionRects(true)

            if let delegate = delegate {
                delegate.sliderDidEndSliding()
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if draggingKnob {
            draggingKnob = false
            if shouldPopupOnDrag { timeLayer().popupScale = 0 }
            recalculatePositionRects(true)

            if let delegate = delegate {
                delegate.sliderDidSlide(to: currentTime)
                delegate.sliderDidEndSliding()
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !draggingKnob { return }

        if let firstTouch = touches.first {
            let touchPoint = firstTouch.location(in: self)

            if touchPoint.x < sidePadding + (timeLayer().knobRect.width / 2) {
                currentTime = 0
            } else if touchPoint.x > (bounds.width - (timeLayer().knobRect.width / 2) - sidePadding) {
                currentTime = totalDuration
            } else {
                let percentage = TimeInterval((touchPoint.x - sidePadding) / (bounds.width - (sidePadding * 2)))
                currentTime = totalDuration * percentage
            }

            timeLayer().popupValue = TimeFormatter.shared.playTimeFormat(time: currentTime) as NSString
            recalculatePositionRects(false)
            if let delegate = delegate {
                delegate.sliderDidProvisionallySlide(to: currentTime)
            }
        }
    }

    // MARK: - Position calculations

    private func recalculatePositionRects(_ animated: Bool) {
        let availableWidth = bounds.width - (sidePadding * 2)
        let progressSize = CGFloat(currentTime / totalDuration) * availableWidth
        let viewCenterWithOffset = (bounds.height / 2) + topOffset
        let knobWidth = draggingKnob ? 16 : 12 as CGFloat
        let lineHeight = draggingKnob ? 6 : 4 as CGFloat

        if !animated {
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        }
        timeLayer().leftHalfRect = CGRect(x: sidePadding, y: viewCenterWithOffset - (lineHeight / 2), width: progressSize, height: lineHeight)
        timeLayer().rightHalfRect = CGRect(x: sidePadding + progressSize, y: viewCenterWithOffset - (lineHeight / 2), width: availableWidth - progressSize, height: lineHeight)

        var knobX = max(sidePadding, sidePadding + progressSize - (knobWidth / 2))
        knobX = min(knobX, sidePadding + availableWidth - knobWidth)
        timeLayer().knobRect = CGRect(x: knobX, y: viewCenterWithOffset - (knobWidth / 2), width: knobWidth, height: knobWidth)
        if !animated {
            CATransaction.commit()
        }
    }

    // MARK: - Layer methods

    private func timeLayer() -> TimeSliderLayer {
        layer as! TimeSliderLayer
    }

    override class var layerClass: AnyClass {
        TimeSliderLayer.self
    }
}

private extension TimeInterval {
    /// Base value is the number of seconds which should be skipped from a given track length
    private static let secondsToSkipConverter = UnitConverterLinear(coefficient: 0.075, constant: 12)

    /// Calculates the skip time for a given total time in a track
    /// This is a linear equation which increases as time scales
    /// - Parameter length: The total length of time for the track
    /// - Returns: The time to skip by
    var skipLength: TimeInterval {
        TimeInterval.secondsToSkipConverter.baseUnitValue(fromValue: self)
    }
}

private extension TimeInterval {
    /// An accessibility string to be read by voice over. This will be a spelled out version of the TimeInterval.
    /// - Returns: A string to be read by voice over, a spelled out version of the interval with full units.
    func accessibilityValue() -> String {
        let formatStyle = Date.ComponentsFormatStyle(style: .spellOut)
        let origDate = Date()
        let date = Date(timeInterval: self, since: origDate)

        let dateRange = origDate..<date

        return dateRange.formatted(.components(style: .spellOut))
    }
}
