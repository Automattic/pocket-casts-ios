import Foundation

class CustomRefreshControl: UIRefreshControl {
    var perform: ((CustomRefreshControl) -> Void)?

    private let refreshInnerImage = UIImageView()
    private let refreshOuterImage = UIImageView()
    private let refreshLabel = UILabel()

    private enum Constants {
        static let triggerDistance: CGFloat = 140
        static let iconFadeDistance: CGFloat = 70
        static let labelFadeDistance: CGFloat = 45
        static let innerRotationMultiplier: CGFloat = 4
        static let outerRotationMultiplier: CGFloat = 2
        static let messageDwell: TimeInterval = 0.25
        static let iconToLabelSpacing: CGFloat = 35
    }

    var customTintColor: UIColor = UIColor(hex: "#B8C3C9") {
        didSet {
            refreshLabel.textColor = customTintColor
            refreshInnerImage.tintColor = customTintColor
            refreshOuterImage.tintColor = customTintColor
        }
    }

    private var isFinishingRefresh = false

    override init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        refreshLabel.textColor = customTintColor
        refreshLabel.alpha = 0
        refreshLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(refreshLabel)

        refreshInnerImage.image = UIImage(named: "refresh_inner")?.withRenderingMode(.alwaysTemplate)
        refreshInnerImage.tintColor = customTintColor
        refreshInnerImage.alpha = 0
        refreshInnerImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(refreshInnerImage)

        refreshOuterImage.image = UIImage(named: "refresh_outer")?.withRenderingMode(.alwaysTemplate)
        refreshOuterImage.tintColor = customTintColor
        refreshOuterImage.alpha = 0
        refreshOuterImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(refreshOuterImage)

        NSLayoutConstraint.activate([
            refreshLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            refreshLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            refreshLabel.topAnchor.constraint(equalTo: topAnchor, constant: Constants.iconToLabelSpacing),
            refreshInnerImage.centerXAnchor.constraint(equalTo: centerXAnchor),
            refreshInnerImage.topAnchor.constraint(equalTo: topAnchor),
            refreshOuterImage.centerXAnchor.constraint(equalTo: centerXAnchor),
            refreshOuterImage.topAnchor.constraint(equalTo: refreshInnerImage.topAnchor),
        ])

        addTarget(self, action: #selector(didTriggerRefresh), for: .valueChanged)
    }

    @objc private func didTriggerRefresh() {
        startRefreshAnimation()
        perform?(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !isRefreshing, let scrollView = superview as? UIScrollView else { return }

        // Measure pull relative to the scroll view's rest position so we account
        // for safe area and any custom contentInset.
        let pull = -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top)

        // Restore the default label once the control fully retracts after a refresh.
        if pull <= 0, refreshLabel.text != L10n.refreshControlPullToRefresh {
            refreshLabel.text = L10n.refreshControlPullToRefresh
        }

        // Icon and label fade on independent curves so the label appears slightly
        // after the icon — closer to native pull-to-refresh.
        let iconStart = Constants.triggerDistance - Constants.iconFadeDistance
        let labelStart = Constants.triggerDistance - Constants.labelFadeDistance
        let iconAlpha = max(0, min(1, (pull - iconStart) / Constants.iconFadeDistance))
        refreshInnerImage.alpha = iconAlpha
        refreshOuterImage.alpha = iconAlpha
        refreshLabel.alpha = max(0, min(1, (pull - labelStart) / Constants.labelFadeDistance))

        refreshInnerImage.transform = CGAffineTransform(rotationAngle: (pull * Constants.innerRotationMultiplier).degreesToRadians)
        refreshOuterImage.transform = CGAffineTransform(rotationAngle: (pull * Constants.outerRotationMultiplier).degreesToRadians)
    }

    override func endRefreshing() {
        // Re-entry from the delayed dispatch: actually retract now.
        if isFinishingRefresh {
            isFinishingRefresh = false
            super.endRefreshing()
            endRefreshAnimation()
            return
        }
        // First call: hold the completion message visible briefly before the native retract.
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.messageDwell) { [weak self] in
            guard let self else { return }
            self.isFinishingRefresh = true
            self.endRefreshing()
        }
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
