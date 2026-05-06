import Foundation

class CustomRefreshControl: UIRefreshControl {
    var perform: ((CustomRefreshControl) -> Void)?

    private let refreshInnerImage = UIImageView()
    private let refreshOuterImage = UIImageView()
    private let refreshLabel = UILabel()

    private enum Layout {
        static let iconFadeStart: CGFloat = 70
        static let iconFadeDistance: CGFloat = 70
        static let labelFadeStart: CGFloat = 95
        static let labelFadeDistance: CGFloat = 45
        static let innerRotationMultiplier: CGFloat = 4
        static let outerRotationMultiplier: CGFloat = 2
        static let messageDwell: TimeInterval = 0.25
        static let fadeOutDuration: TimeInterval = 0.2
        static let iconToLabelSpacing: CGFloat = 35
    }

    var style: ThemeStyle = .secondaryText02 {
        didSet { updateTintColor() }
    }

    var themeOverride: Theme.ThemeType? {
        didSet { updateTintColor() }
    }

    /// When set, overrides the theme-based tint color. Set to `nil` to fall back to the theme.
    var customTintColor: UIColor? {
        didSet { updateTintColor() }
    }

    private var isFinishingRefresh = false
    private var isHiding = false

    override init() {
        super.init(frame: .zero)
        setupView()
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(restartAnimationIfNeeded), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func set(text: String) {
        refreshLabel.text = text
    }

    private func setupView() {
        // Hide the default spinner; we draw our own visuals on top.
        tintColor = .clear

        refreshLabel.text = L10n.refreshControlPullToRefresh
        refreshLabel.textAlignment = .center
        refreshLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        refreshLabel.alpha = 0
        refreshLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(refreshLabel)

        refreshInnerImage.image = UIImage(named: "refresh_inner")?.withRenderingMode(.alwaysTemplate)
        refreshInnerImage.alpha = 0
        refreshInnerImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(refreshInnerImage)

        refreshOuterImage.image = UIImage(named: "refresh_outer")?.withRenderingMode(.alwaysTemplate)
        refreshOuterImage.alpha = 0
        refreshOuterImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(refreshOuterImage)

        NSLayoutConstraint.activate([
            refreshLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            refreshLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            refreshLabel.topAnchor.constraint(equalTo: topAnchor, constant: Layout.iconToLabelSpacing),
            refreshInnerImage.centerXAnchor.constraint(equalTo: centerXAnchor),
            refreshInnerImage.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            refreshOuterImage.centerXAnchor.constraint(equalTo: centerXAnchor),
            refreshOuterImage.topAnchor.constraint(equalTo: refreshInnerImage.topAnchor),
        ])

        updateTintColor()

        addTarget(self, action: #selector(didTriggerRefresh), for: .valueChanged)
    }

    @objc private func themeDidChange() {
        updateTintColor()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        restartAnimationIfNeeded()
    }

    @objc private func restartAnimationIfNeeded() {
        // CAAnimations are stripped when the layer leaves the window or the app
        // backgrounds; re-add them so the spinner keeps animating on return.
        guard isRefreshing, window != nil else { return }
        startRefreshAnimation()
    }

    private func updateTintColor() {
        let color = customTintColor ?? AppTheme.colorForStyle(style, themeOverride: themeOverride)
        refreshLabel.textColor = color
        refreshInnerImage.tintColor = color
        refreshOuterImage.tintColor = color
    }

    @objc private func didTriggerRefresh() {
        startRefreshAnimation()
        perform?(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let scrollView = superview as? UIScrollView else { return }

        // Measure pull relative to the scroll view's rest position so we account
        // for safe area and any custom contentInset.
        let pull = -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top)

        // Skip alpha updates while the fade-out animation is running.
        if isHiding { return }

        // While refreshing, the hold position sits at pull == 0 (the inset is
        // expanded by UIKit). As the user scrolls past it, pull goes negative;
        // fade out over the control's own height so the visuals don't overlay
        // the content below.
        if isRefreshing {
            let fadeDistance = max(1, bounds.height)
            let alpha = max(0, min(1, (pull + fadeDistance) / fadeDistance))
            refreshInnerImage.alpha = alpha
            refreshOuterImage.alpha = alpha
            refreshLabel.alpha = alpha
            return
        }

        // Restore the default label once the control fully retracts after a refresh.
        if pull <= 0, refreshLabel.text != L10n.refreshControlPullToRefresh {
            refreshLabel.text = L10n.refreshControlPullToRefresh
        }

        // Icon and label fade on independent curves so the label appears slightly
        // after the icon — closer to native pull-to-refresh.
        let iconAlpha = max(0, min(1, (pull - Layout.iconFadeStart) / Layout.iconFadeDistance))
        refreshInnerImage.alpha = iconAlpha
        refreshOuterImage.alpha = iconAlpha
        refreshLabel.alpha = max(0, min(1, (pull - Layout.labelFadeStart) / Layout.labelFadeDistance))

        refreshInnerImage.transform = CGAffineTransform(rotationAngle: (pull * Layout.innerRotationMultiplier).degreesToRadians)
        refreshOuterImage.transform = CGAffineTransform(rotationAngle: (pull * Layout.outerRotationMultiplier).degreesToRadians)
    }

    override func endRefreshing() {
        // Re-entry from the fade-out completion: actually retract now.
        if isFinishingRefresh {
            isFinishingRefresh = false
            isHiding = false
            super.endRefreshing()
            endRefreshAnimation()
            return
        }
        // Hold the completion message briefly, then fade the visuals out before the native retract.
        isHiding = true
        UIView.animate(withDuration: Layout.fadeOutDuration, delay: Layout.messageDwell, animations: { [weak self] in
            self?.refreshInnerImage.alpha = 0
            self?.refreshOuterImage.alpha = 0
            self?.refreshLabel.alpha = 0
        }, completion: { [weak self] _ in
            guard let self else { return }
            self.isFinishingRefresh = true
            self.endRefreshing()
        })
    }

    private func startRefreshAnimation() {
        let duration: CFTimeInterval = 1.0

        let innerRotation = CABasicAnimation(keyPath: "transform.rotation.z")
        innerRotation.fromValue = 0
        innerRotation.toValue = Double.pi * 2
        innerRotation.duration = duration
        innerRotation.repeatCount = .infinity
        refreshInnerImage.layer.add(innerRotation, forKey: nil)

        let outerRotation = CABasicAnimation(keyPath: "transform.rotation.z")
        outerRotation.fromValue = 0
        outerRotation.toValue = Double.pi * 2
        outerRotation.duration = duration * 1.5
        outerRotation.repeatCount = .infinity
        refreshOuterImage.layer.add(outerRotation, forKey: nil)
    }

    private func endRefreshAnimation() {
        refreshInnerImage.layer.removeAllAnimations()
        refreshOuterImage.layer.removeAllAnimations()
    }
}
