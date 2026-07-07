import UIKit

/// A single-line title view that fades content past its leading and trailing
/// edges with a gradient mask instead of truncating with an ellipsis. When
/// the text is too long to fit, the contents periodically scroll horizontally
/// — a duplicate of the text follows behind a small gap so that as the end of
/// the title approaches the leading edge, the beginning of the title is
/// already entering from the trailing edge. Each cycle is followed by a brief
/// pause before the next one begins.
final class MiniPlayerScrollingTitleView: UIView {
    private let scrollContainer = UIView()
    private let primaryLabel = UILabel()
    private let trailingLabel = UILabel()
    private let gradientMask = CAGradientLayer()

    private var lastTextWidth: CGFloat = -1
    private var lastBoundsWidth: CGFloat = -1

    private let fadeWidth: CGFloat = 16
    private let scrollSpeed: CGFloat = 30
    private let gap: CGFloat = 28
    private let pauseDuration: TimeInterval = 5.0
    private let maskTransitionDuration: TimeInterval = 0.35

    private static let transformAnimationKey = "marquee.transform"
    private static let maskAnimationKey = "marquee.mask"

    var text: String? {
        get { primaryLabel.text }
        set {
            guard primaryLabel.text != newValue else { return }
            primaryLabel.text = newValue
            trailingLabel.text = newValue
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    var textColor: UIColor? {
        get { primaryLabel.textColor }
        set {
            primaryLabel.textColor = newValue
            trailingLabel.textColor = newValue
        }
    }

    var font: UIFont? {
        get { primaryLabel.font }
        set {
            primaryLabel.font = newValue
            trailingLabel.font = newValue
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    init() {
        super.init(frame: .zero)

        addSubview(scrollContainer)

        for label in [primaryLabel, trailingLabel] {
            label.numberOfLines = 1
            label.lineBreakMode = .byClipping
            label.adjustsFontForContentSizeCategory = true
            scrollContainer.addSubview(label)
        }

        gradientMask.startPoint = CGPoint(x: 0, y: 0.5)
        gradientMask.endPoint = CGPoint(x: 1, y: 0.5)
        gradientMask.colors = [
            UIColor.clear.cgColor,
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.clear.cgColor,
        ]

        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceMotionStatusDidChange),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: MiniPlayerScrollingTitleView, _) in
            view.invalidateIntrinsicContentSize()
            view.setNeedsLayout()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Restarts the marquee from the beginning of its pause-then-scroll cycle.
    func restartAnimation() {
        scheduleAnimation()
    }

    /// Picks up another instance's marquee phase, so a snapshot clone scrolls
    /// in lock-step with the live mini player instead of restarting from
    /// frame zero. Call after this view is in a window so layer-local time
    /// conversion is well-defined.
    func synchronizeAnimation(with other: MiniPlayerScrollingTitleView) {
        let otherLayer = other.scrollContainer.layer
        guard let transformAnim = otherLayer.animation(forKey: Self.transformAnimationKey),
              let maskAnim = other.gradientMask.animation(forKey: Self.maskAnimationKey),
              let transformCopy = transformAnim.copy() as? CAAnimation,
              let maskCopy = maskAnim.copy() as? CAAnimation else { return }

        // Translate beginTime from the source layer's local time space to
        // ours via host time — the same numerical value can map to a
        // different phase across layer hierarchies, which is why the previous
        // direct-copy attempt didn't fully sync.
        let beginInHost = otherLayer.convertTime(transformAnim.beginTime, to: nil)
        let beginInLocal = scrollContainer.layer.convertTime(beginInHost, from: nil)
        transformCopy.beginTime = beginInLocal
        maskCopy.beginTime = beginInLocal

        layer.mask = gradientMask
        scrollContainer.layer.add(transformCopy, forKey: Self.transformAnimationKey)
        gradientMask.add(maskCopy, forKey: Self.maskAnimationKey)
    }

    @objc private func reduceMotionStatusDidChange() {
        scheduleAnimation()
    }

    override var intrinsicContentSize: CGSize {
        let textWidth = primaryLabel.intrinsicContentSize.width
        let height = ceil(primaryLabel.font?.lineHeight ?? UIFont.systemFontSize)
        return CGSize(width: textWidth, height: height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let textWidth = primaryLabel.intrinsicContentSize.width
        let needsScrolling = textWidth > bounds.width + 0.5

        scrollContainer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        primaryLabel.frame = CGRect(x: 0, y: 0, width: max(textWidth, bounds.width), height: bounds.height)
        if needsScrolling {
            trailingLabel.isHidden = false
            trailingLabel.frame = CGRect(x: textWidth + gap, y: 0, width: textWidth, height: bounds.height)
        } else {
            trailingLabel.isHidden = true
        }

        gradientMask.frame = bounds

        if needsScrolling {
            if layer.mask !== gradientMask {
                layer.mask = gradientMask
            }
            if gradientMask.animation(forKey: Self.maskAnimationKey) == nil {
                applyStaticMask()
            }
        } else {
            layer.mask = nil
        }

        if textWidth != lastTextWidth || bounds.width != lastBoundsWidth {
            lastTextWidth = textWidth
            lastBoundsWidth = bounds.width
            scheduleAnimation()
        }
    }

    private func maskLocations(leadingOpen: Bool) -> [NSNumber] {
        let fadeFraction = Float(min(0.4, fadeWidth / bounds.width))
        return [
            0,
            NSNumber(value: leadingOpen ? fadeFraction : 0),
            NSNumber(value: 1 - fadeFraction),
            1,
        ]
    }

    private func applyStaticMask() {
        guard bounds.width > 0 else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientMask.locations = maskLocations(leadingOpen: false)
        CATransaction.commit()
    }

    private func scheduleAnimation() {
        scrollContainer.layer.removeAnimation(forKey: Self.transformAnimationKey)
        gradientMask.removeAnimation(forKey: Self.maskAnimationKey)

        let textWidth = primaryLabel.intrinsicContentSize.width
        let needsScrolling = textWidth > bounds.width + 0.5

        guard needsScrolling, bounds.width > 0, window != nil, !UIAccessibility.isReduceMotionEnabled else {
            return
        }

        addMarqueeAnimations()
    }

    private func addMarqueeAnimations() {
        let textWidth = primaryLabel.intrinsicContentSize.width
        let cycleDistance = textWidth + gap
        let scrollDuration = TimeInterval(cycleDistance / scrollSpeed)
        let preGapDuration = TimeInterval(textWidth / scrollSpeed)
        let gapDuration = TimeInterval(gap / scrollSpeed)
        let totalDuration = pauseDuration + scrollDuration

        guard totalDuration > 0 else { return }

        let beginTime = CACurrentMediaTime()

        let transformAnim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        transformAnim.values = [0, 0, -cycleDistance]
        transformAnim.keyTimes = [
            0,
            NSNumber(value: pauseDuration / totalDuration),
            1,
        ]
        transformAnim.timingFunctions = [
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .linear),
        ]
        transformAnim.duration = totalDuration
        transformAnim.repeatCount = .infinity
        transformAnim.beginTime = beginTime
        transformAnim.isRemovedOnCompletion = false
        transformAnim.fillMode = .both

        scrollContainer.layer.add(transformAnim, forKey: Self.transformAnimationKey)

        let closed = maskLocations(leadingOpen: false)
        let open = maskLocations(leadingOpen: true)

        let scrollStart = pauseDuration
        let fadeInEnd = scrollStart + maskTransitionDuration
        let holdEnd = scrollStart + preGapDuration
        let fadeOutDur = min(maskTransitionDuration, gapDuration)
        let fadeOutEnd = scrollStart + preGapDuration + fadeOutDur

        let maskAnim = CAKeyframeAnimation(keyPath: "locations")
        maskAnim.values = [closed, closed, open, open, closed, closed]
        maskAnim.keyTimes = [
            0,
            NSNumber(value: scrollStart / totalDuration),
            NSNumber(value: fadeInEnd / totalDuration),
            NSNumber(value: holdEnd / totalDuration),
            NSNumber(value: fadeOutEnd / totalDuration),
            1,
        ]
        maskAnim.timingFunctions = [
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .linear),
        ]
        maskAnim.duration = totalDuration
        maskAnim.repeatCount = .infinity
        maskAnim.beginTime = beginTime
        maskAnim.isRemovedOnCompletion = false
        maskAnim.fillMode = .both

        gradientMask.add(maskAnim, forKey: Self.maskAnimationKey)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            scrollContainer.layer.removeAnimation(forKey: Self.transformAnimationKey)
            gradientMask.removeAnimation(forKey: Self.maskAnimationKey)
        } else {
            scheduleAnimation()
        }
    }
}
