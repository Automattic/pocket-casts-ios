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

    private var animationTask: Task<Void, Never>?
    private var lastText: String?
    private var lastBoundsWidth: CGFloat = 0

    private let fadeWidth: CGFloat = 16
    private let scrollSpeed: CGFloat = 30
    private let gap: CGFloat = 28
    private let initialDelay: Duration = .seconds(5.0)
    private let betweenCyclesDelay: Duration = .seconds(5.0)
    private let maskTransitionDuration: TimeInterval = 0.35

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
            label.adjustsFontForContentSizeCategory = false
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
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

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
                applyMask(showLeading: false, showTrailing: true)
                layer.mask = gradientMask
            }
        } else {
            layer.mask = nil
        }

        if primaryLabel.text != lastText || bounds.width != lastBoundsWidth {
            lastText = primaryLabel.text
            lastBoundsWidth = bounds.width
            scheduleAnimation()
        }
    }

    private func applyMask(showLeading: Bool, showTrailing: Bool) {
        let width = bounds.width
        guard width > 0 else { return }
        let fadeFraction = min(0.4, fadeWidth / width)
        let leadingEnd = showLeading ? fadeFraction : 0
        let trailingStart = showTrailing ? (1 - fadeFraction) : 1
        gradientMask.locations = [
            0,
            NSNumber(value: Float(leadingEnd)),
            NSNumber(value: Float(trailingStart)),
            1,
        ]
    }

    private func scheduleAnimation() {
        animationTask?.cancel()
        animationTask = nil
        scrollContainer.layer.removeAnimation(forKey: "marquee")

        let textWidth = primaryLabel.intrinsicContentSize.width
        let needsScrolling = textWidth > bounds.width + 0.5

        guard needsScrolling, window != nil else {
            applyMask(showLeading: false, showTrailing: needsScrolling)
            return
        }

        applyMask(showLeading: false, showTrailing: true)

        animationTask = Task { @MainActor [weak self] in
            await self?.runAnimationLoop()
        }
    }

    @MainActor
    private func runAnimationLoop() async {
        do {
            try await Task.sleep(for: initialDelay)
            while !Task.isCancelled {
                let textWidth = primaryLabel.intrinsicContentSize.width
                let cycleDistance = textWidth + gap
                guard cycleDistance > 0 else { return }
                let cycleDuration = TimeInterval(cycleDistance / scrollSpeed)
                let preGapDuration = TimeInterval(textWidth / scrollSpeed)
                let gapDuration = TimeInterval(gap / scrollSpeed)

                UIView.animate(withDuration: maskTransitionDuration, delay: 0, options: [.curveEaseInOut]) {
                    self.applyMask(showLeading: true, showTrailing: true)
                }

                let animation = CABasicAnimation(keyPath: "transform.translation.x")
                animation.fromValue = 0
                animation.toValue = -cycleDistance
                animation.duration = cycleDuration
                animation.timingFunction = CAMediaTimingFunction(name: .linear)
                scrollContainer.layer.add(animation, forKey: "marquee")

                // Fade the leading mask out while the gap (not text) occupies the
                // leading edge — otherwise the start of the title is visibly
                // obscured as it loops back into view.
                try await Task.sleep(for: .seconds(preGapDuration))

                UIView.animate(withDuration: min(maskTransitionDuration, gapDuration), delay: 0, options: [.curveEaseInOut]) {
                    self.applyMask(showLeading: false, showTrailing: true)
                }

                try await Task.sleep(for: .seconds(gapDuration))

                try await Task.sleep(for: betweenCyclesDelay)
            }
        } catch {
            scrollContainer.layer.removeAnimation(forKey: "marquee")
            applyMask(showLeading: false, showTrailing: true)
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            animationTask?.cancel()
            animationTask = nil
            scrollContainer.layer.removeAnimation(forKey: "marquee")
        } else {
            scheduleAnimation()
        }
    }
}
