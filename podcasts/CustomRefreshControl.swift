import Foundation

class CustomRefreshControl: UIRefreshControl {
    var perform: (() -> Void)?

    private var refreshInnerImage = UIImageView()
    private var refreshOuterImage = UIImageView()
    private let innerStartingAngle = -90 as CGFloat
    private let innerEndingAngle = 90 as CGFloat
    private var innerRotationAngle = 0 as CGFloat
    private var outerRotationAngle = 0 as CGFloat
    private var pullDownAmountForRefresh = 170 as CGFloat
    private var refreshLabel = UILabel()
    private var isAnimating = false
    private var didTriggerHaptic = true
    var customTintColor: UIColor = UIColor(hex: "#B8C3C9") {
        didSet {
            refreshLabel.textColor = customTintColor
            refreshInnerImage.tintColor = customTintColor
            refreshOuterImage.tintColor = customTintColor
        }
    }

    override init() {
        super.init(frame: .zero)
        setupView()
        setupLayout()
        alpha = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startRefreshing() {
        beginRefreshing()
        isAnimating = true
        startRefreshAnimation()
        perform?()
    }

    override func endRefreshing() {
        super.endRefreshing()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.endRefreshAnimation()
            self?.isAnimating = false
            self?.alpha = 0
        }
    }

    private func setupView() {
        tintColor = .clear

        refreshLabel.text = L10n.refreshControlPullToRefresh
        refreshLabel.textAlignment = NSTextAlignment.center
        refreshLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold)
        refreshLabel.textColor = customTintColor
        addSubview(refreshLabel)

        refreshInnerImage.image = UIImage(named: "refresh_inner")?.withRenderingMode(.alwaysTemplate)
        refreshInnerImage.tintColor = customTintColor
        addSubview(refreshInnerImage)

        refreshOuterImage.image = UIImage(named: "refresh_outer")?.withRenderingMode(.alwaysTemplate)
        refreshOuterImage.tintColor = customTintColor
        addSubview(refreshOuterImage)

        addTarget(self, action: #selector(beginRefreshing), for: .valueChanged)
    }

    private func setupLayout() {
        refreshLabel.translatesAutoresizingMaskIntoConstraints = false
        refreshLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        refreshLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        refreshLabel.topAnchor.constraint(equalTo: topAnchor, constant: 50).isActive = true

        refreshInnerImage.translatesAutoresizingMaskIntoConstraints = false
        refreshInnerImage.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        refreshInnerImage.topAnchor.constraint(equalTo: topAnchor, constant: 15).isActive = true

        refreshOuterImage.translatesAutoresizingMaskIntoConstraints = false
        refreshOuterImage.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        refreshOuterImage.topAnchor.constraint(equalTo: topAnchor, constant: 15).isActive = true
    }

    private func startRefreshAnimation() {
        let cfDuration = CFTimeInterval(1.0)

        let innerRotation = CABasicAnimation(keyPath: "transform.rotation.z")
        innerRotation.fromValue = innerRotationAngle
        innerRotation.toValue = Double(innerRotationAngle) + (Double.pi * 2)
        innerRotation.duration = cfDuration
        innerRotation.repeatCount = Float.infinity
        refreshInnerImage.layer.add(innerRotation, forKey: nil)

        let outerRotation = CABasicAnimation(keyPath: "transform.rotation.z")
        outerRotation.fromValue = outerRotationAngle
        outerRotation.toValue = Double(outerRotationAngle) + (Double.pi * 2)
        outerRotation.duration = cfDuration * 1.5
        outerRotation.repeatCount = Float.infinity
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

        if isAnimating {
            endRefreshing()
        }
    }

    private func processRefreshCompleted(_ message: String) {
        refreshLabel.text = message.uppercased()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            UIView.animate(withDuration: 0.2, animations: {
                self?.alpha = 0
            }, completion: { _ in
                self?.endRefreshing()
            })
        }
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
        let scrollAmount = -scrollView.contentOffset.y
        if scrollAmount > 100 {
            didPullDown(scrollAmount)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView) {
        let scrollAmount = -scrollView.contentOffset.y
        if scrollAmount > 0 {
            didEndDraggingAt(scrollAmount)
        }
    }

    private func didPullDown(_ amount: CGFloat) {
        if isAnimating {
            return
        }

        let adjustedAmount = min(pullDownAmountForRefresh, amount)
        let alphaValue = amount / pullDownAmountForRefresh
        if adjustedAmount < pullDownAmountForRefresh {
            refreshLabel.text = L10n.refreshControlPullToRefresh
            didTriggerHaptic = false
        } else {
            refreshLabel.text = L10n.refreshControlReleaseToRefresh

            // Only fire the haptic once per "release" state
            if !didTriggerHaptic {
                didTriggerHaptic = true

                HapticsHelper.triggerPullToRefreshHaptic()
            }
        }

        innerRotationAngle = (amount * 4).degreesToRadians
        refreshInnerImage.transform = CGAffineTransform(rotationAngle: innerRotationAngle)

        outerRotationAngle = (amount * 2).degreesToRadians
        refreshOuterImage.transform = CGAffineTransform(rotationAngle: outerRotationAngle)

        alpha = amount >= 150.0 ? alphaValue : 0.0
    }

    private func didEndDraggingAt(_ position: CGFloat) {
        if position > pullDownAmountForRefresh {
            startRefreshing()
        }
    }
}
