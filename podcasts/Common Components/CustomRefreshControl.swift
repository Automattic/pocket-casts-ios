import Foundation

class CustomRefreshControl: UIRefreshControl {
    var perform: ((CustomRefreshControl) -> Void)?

    private var refreshInnerImage = UIImageView()
    private var refreshOuterImage = UIImageView()
    private var innerRotationAngle: CGFloat = 0
    private var outerRotationAngle: CGFloat = 0
    private let refreshLabel = UILabel()
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private var isPastThreshold = false
    private var didPrepareHaptic = false
    private var isDismissalPending = false

    private enum Constants {
        // MARK: Pull
        static let triggerDistance: CGFloat = 140
        static let iconFadeDistance: CGFloat = 70
        static let labelFadeDistance: CGFloat = 45
        static let hapticPrepareDistance: CGFloat = 30
        static let innerRotationMultiplier: CGFloat = 4
        static let outerRotationMultiplier: CGFloat = 2

        // MARK: Dismissal
        static let messageDwell: TimeInterval = 0.25
        static let fadeDuration: TimeInterval = 0.2
    }

    var customTintColor: UIColor = UIColor(hex: "#B8C3C9") {
        didSet {
            refreshLabel.textColor = customTintColor
            refreshInnerImage.tintColor = customTintColor
            refreshOuterImage.tintColor = customTintColor
        }
    }

    /// Top inset for the spinner icon. The label sits a fixed distance below the icon.
    var topInset: CGFloat = 15 {
        didSet {
            guard topInset != oldValue else { return }
            setNeedsUpdateConstraints()
        }
    }

    private enum Layout {
        static let iconToLabelSpacing: CGFloat = 35
    }

    private var customConstraints: [NSLayoutConstraint] = []

    override init() {
        super.init(frame: .zero)
        setupView()
        alpha = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func endRefreshing() {
        // Defer dismissal until the user releases their touch so the
        // completion message doesn't disappear mid-pull on a fast network —
        // matches native UIRefreshControl behaviour. `scrollViewDidScroll`
        // (forwarded by the host view controller) re-enters here once
        // `isTracking` flips to false during the bounce-back.
        if let scrollView = superview as? UIScrollView, scrollView.isTracking {
            isDismissalPending = true
            return
        }
        isDismissalPending = false

        UIView.animate(withDuration: Constants.fadeDuration, delay: Constants.messageDwell, options: [], animations: {
            self.alpha = 0
        }, completion: { _ in
            super.endRefreshing()
            self.endRefreshAnimation()
        })
    }

    func set(text: String) {
        refreshLabel.text = text
    }

    private func setupView() {
        tintColor = .clear

        refreshLabel.text = L10n.refreshControlPullToRefresh
        refreshLabel.textAlignment = .center
        refreshLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        refreshLabel.textColor = customTintColor
        refreshLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(refreshLabel)

        refreshInnerImage.image = UIImage(named: "refresh_inner")?.withRenderingMode(.alwaysTemplate)
        refreshInnerImage.tintColor = customTintColor
        refreshInnerImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(refreshInnerImage)

        refreshOuterImage.image = UIImage(named: "refresh_outer")?.withRenderingMode(.alwaysTemplate)
        refreshOuterImage.tintColor = customTintColor
        refreshOuterImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(refreshOuterImage)

        addTarget(self, action: #selector(didTriggerRefresh), for: .valueChanged)
    }

    @objc private func didTriggerRefresh() {
        startRefreshAnimation()
        perform?(self)
    }

    override func updateConstraints() {
        NSLayoutConstraint.deactivate(customConstraints)
        customConstraints = [
            refreshLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            refreshLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            refreshLabel.topAnchor.constraint(equalTo: topAnchor, constant: topInset + Layout.iconToLabelSpacing),
            refreshInnerImage.centerXAnchor.constraint(equalTo: centerXAnchor),
            refreshInnerImage.topAnchor.constraint(equalTo: topAnchor, constant: topInset),
            refreshOuterImage.centerXAnchor.constraint(equalTo: centerXAnchor),
            refreshOuterImage.topAnchor.constraint(equalTo: refreshInnerImage.topAnchor),
        ]
        NSLayoutConstraint.activate(customConstraints)
        super.updateConstraints()
    }

    private func startRefreshAnimation() {
        let duration: CFTimeInterval = 1.0

        let innerRotation = CABasicAnimation(keyPath: "transform.rotation.z")
        innerRotation.fromValue = innerRotationAngle
        innerRotation.toValue = Double(innerRotationAngle) + (Double.pi * 2)
        innerRotation.duration = duration
        innerRotation.repeatCount = .infinity
        refreshInnerImage.layer.add(innerRotation, forKey: nil)

        let outerRotation = CABasicAnimation(keyPath: "transform.rotation.z")
        outerRotation.fromValue = outerRotationAngle
        outerRotation.toValue = Double(outerRotationAngle) + (Double.pi * 2)
        outerRotation.duration = duration * 1.5
        outerRotation.repeatCount = .infinity
        refreshOuterImage.layer.add(outerRotation, forKey: nil)
    }

    private func endRefreshAnimation() {
        refreshInnerImage.layer.removeAllAnimations()
        refreshOuterImage.layer.removeAllAnimations()
    }
}

// MARK: - Notifications Handling

extension CustomRefreshControl {
    func parentViewControllerDidAppear() {
        let notifCenter = NotificationCenter.default
        notifCenter.addObserver(self, selector: #selector(loading), name: PodcastFeedReloadNotification.loading, object: nil)
        notifCenter.addObserver(self, selector: #selector(episodesFound), name: PodcastFeedReloadNotification.episodesFound, object: nil)
        notifCenter.addObserver(self, selector: #selector(noEpisodesFound), name: PodcastFeedReloadNotification.noEpisodesFound, object: nil)
    }

    func parentViewControllerDidDisappear() {
        let notifCenter = NotificationCenter.default
        notifCenter.removeObserver(self, name: PodcastFeedReloadNotification.loading, object: nil)
        notifCenter.removeObserver(self, name: PodcastFeedReloadNotification.episodesFound, object: nil)
        notifCenter.removeObserver(self, name: PodcastFeedReloadNotification.noEpisodesFound, object: nil)

        if isRefreshing {
            endRefreshing()
        }
    }

    private func processRefreshCompleted(_ message: String) {
        refreshLabel.text = message.uppercased()
        endRefreshing()
    }

    @objc private func loading() {
        refreshLabel.text = L10n.podcastFeedReloadLoading.uppercased()
    }

    @objc private func episodesFound() {
        processRefreshCompleted(L10n.podcastFeedReloadNewEpisodesFound)
    }

    @objc private func noEpisodesFound() {
        processRefreshCompleted(L10n.podcastFeedReloadNoEpisodesFound)
    }
}

// MARK: - Scroll Handling

extension CustomRefreshControl {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // A deferred dismissal is waiting for the user to release. Once the
        // scroll view stops tracking, run the dismissal — re-entering
        // `endRefreshing` proceeds past the tracking guard now that
        // `isTracking` is false.
        if isDismissalPending && !scrollView.isTracking {
            endRefreshing()
            return
        }

        guard !isRefreshing else { return }

        // Only respond to interactive drag; ignore programmatic scrolls (e.g. scroll-to-top).
        guard scrollView.isTracking else {
            alpha = 0
            didPrepareHaptic = false
            return
        }

        // Measure pull relative to the scroll view's rest position so we account for
        // safe area and any custom contentInset (e.g. PCSearchBarController's pinned bar).
        let scrollAmount = -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top)

        if scrollAmount > Constants.hapticPrepareDistance && !didPrepareHaptic {
            feedbackGenerator.prepare()
            didPrepareHaptic = true
        }

        // Icon and label fade on independent curves so the label appears slightly after
        // the icon — closer to the native pull-to-refresh behaviour.
        let iconStart = Constants.triggerDistance - Constants.iconFadeDistance
        let labelStart = Constants.triggerDistance - Constants.labelFadeDistance
        let iconAlpha = max(0, min(1, (scrollAmount - iconStart) / Constants.iconFadeDistance))
        let labelAlpha = max(0, min(1, (scrollAmount - labelStart) / Constants.labelFadeDistance))

        alpha = 1
        refreshInnerImage.alpha = iconAlpha
        refreshOuterImage.alpha = iconAlpha
        refreshLabel.alpha = labelAlpha

        let pastThreshold = scrollAmount >= Constants.triggerDistance
        if pastThreshold != isPastThreshold {
            isPastThreshold = pastThreshold
            refreshLabel.text = pastThreshold
                ? L10n.refreshControlReleaseToRefresh
                : L10n.refreshControlPullToRefresh
            if pastThreshold {
                feedbackGenerator.impactOccurred()
            }
        }

        innerRotationAngle = (scrollAmount * Constants.innerRotationMultiplier).degreesToRadians
        refreshInnerImage.transform = CGAffineTransform(rotationAngle: innerRotationAngle)

        outerRotationAngle = (scrollAmount * Constants.outerRotationMultiplier).degreesToRadians
        refreshOuterImage.transform = CGAffineTransform(rotationAngle: outerRotationAngle)
    }
}
