import PocketCastsServer
import UIKit

class PCRefreshControl: UIView {
    var refreshing = false

    var refreshLabel = UILabel()
    private var refreshInnerImage = UIImageView()
    private var refreshOuterImage = UIImageView()

    private var pullDownAmountForRefresh = RefreshDefaults.pullDownAmount
    private var viewHeight = RefreshDefaults.viewHeight

    private let innerStartingAngle = -90 as CGFloat
    private let innerEndingAngle = 90 as CGFloat
    private var innerRotationAngle = 0 as CGFloat
    private var outerRotationAngle = 0 as CGFloat

    private weak var scrollView: UIScrollView?
    private weak var searchBar: PCSearchBarController?
    private weak var navBar: UINavigationBar?

    var parentViewVisible = false
    var didBeginRefreshing: (()->())?

    override var bounds: CGRect {
        didSet {
            resetOffsetOnBoundsChangeIfNeeded()
        }
    }

    let source: AnalyticsSource

    init(scrollView: UIScrollView, navBar: UINavigationBar, searchBar: PCSearchBarController? = nil, source: AnalyticsSource) {
        self.source = source
        super.init(frame: CGRect.zero)

        clipsToBounds = true
        backgroundColor = UIColor.clear

        self.scrollView = scrollView
        self.navBar = navBar
        self.searchBar = searchBar

        scrollView.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.trailingAnchor).isActive = true
        heightAnchor.constraint(equalToConstant: viewHeight).isActive = true
        widthAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.widthAnchor).isActive = true
        topAnchor.constraint(equalTo: scrollView.topAnchor, constant: -viewHeight).isActive = true
        alpha = 0

        // refresh label
        refreshLabel.text = L10n.refreshControlPullToRefresh
        refreshLabel.textAlignment = NSTextAlignment.center
        refreshLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold)
        refreshLabel.textColor = UIColor(hex: "#B8C3C9")
        addSubview(refreshLabel)
        refreshLabel.translatesAutoresizingMaskIntoConstraints = false
        refreshLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        refreshLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        refreshLabel.topAnchor.constraint(equalTo: topAnchor, constant: 50).isActive = true

        refreshInnerImage.image = UIImage(named: "refresh_inner")
        addSubview(refreshInnerImage)
        refreshInnerImage.translatesAutoresizingMaskIntoConstraints = false
        refreshInnerImage.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        refreshInnerImage.topAnchor.constraint(equalTo: topAnchor, constant: 15).isActive = true

        refreshOuterImage.image = UIImage(named: "refresh_outer")
        addSubview(refreshOuterImage)
        refreshOuterImage.translatesAutoresizingMaskIntoConstraints = false
        refreshOuterImage.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        refreshOuterImage.topAnchor.constraint(equalTo: topAnchor, constant: 15).isActive = true

        // Recalculate some values
        // We recalculate the view height after we set the constraints so the UI gets pinned to the bottom of the view
        // if the height expands
        calculateViewHeight()
        calculatePullDownAmount()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func parentViewControllerDidDisappear() {
        parentViewVisible = false

        let notifCenter = NotificationCenter.default
        notifCenter.removeObserver(self, name: ServerNotifications.podcastsRefreshed, object: nil)
        notifCenter.removeObserver(self, name: ServerNotifications.podcastRefreshFailed, object: nil)
        notifCenter.removeObserver(self, name: Constants.Notifications.opmlImportCompleted, object: nil)
        notifCenter.removeObserver(self, name: ServerNotifications.syncCompleted, object: nil)
        notifCenter.removeObserver(self, name: ServerNotifications.syncFailed, object: nil)
        notifCenter.removeObserver(self, name: ServerNotifications.podcastRefreshThrottled, object: nil)

        if refreshing {
            endRefreshing(false)
        }
    }

    func parentViewControllerDidAppear() {
        parentViewVisible = true

        let notifCenter = NotificationCenter.default
        notifCenter.addObserver(self, selector: #selector(podcastsRefreshed), name: ServerNotifications.podcastsRefreshed, object: nil)
        notifCenter.addObserver(self, selector: #selector(podcastRefreshFailed), name: ServerNotifications.podcastRefreshFailed, object: nil)
        notifCenter.addObserver(self, selector: #selector(podcastsRefreshed), name: Constants.Notifications.opmlImportCompleted, object: nil)
        notifCenter.addObserver(self, selector: #selector(syncCompleted), name: ServerNotifications.syncCompleted, object: nil)
        notifCenter.addObserver(self, selector: #selector(syncCompleted), name: ServerNotifications.podcastRefreshThrottled, object: nil)
        notifCenter.addObserver(self, selector: #selector(syncFailed), name: ServerNotifications.syncFailed, object: nil)
    }

    func beginRefreshing() {
        refreshing = true

        UIView.animate(withDuration: 0.2, animations: {
            self.offsetToPullDown()
        })

        refreshLabel.text = L10n.refreshControlFetchingEpisodes
        startRefreshAnimation()

        RefreshManager.shared.refreshPodcasts()
        Analytics.track(.pulledToRefresh, properties: ["source": source])
        self.didBeginRefreshing?()
    }

    func endRefreshing(_ animated: Bool) {
        if !refreshing { return }

        if animated {
            UIView.animate(withDuration: 0.4, animations: {
                self.resetOffset()
            }, completion: { _ in
                self.endRefreshAnimation()
                self.refreshing = false
            })
        } else {
            resetOffset()
            endRefreshAnimation()
            refreshing = false
        }
    }

    // MARK: - Table Offset

    func offsetToPullDown() {
        if let scrollView = scrollView {
            scrollView.contentInset = UIEdgeInsets(top: viewHeight, left: scrollView.contentInset.left, bottom: scrollView.contentInset.bottom, right: scrollView.contentInset.right)
        }
    }

    func resetOffset() {
        guard let scrollView = scrollView else {
            return
        }

        // After refreshing we'll reset the top offer to the height of the search bar if it's available
        let topOffset = searchBar != nil ? PCSearchBarController.defaultHeight : 0
        scrollView.contentInset = UIEdgeInsets(top: topOffset, left: scrollView.contentInset.left, bottom: scrollView.contentInset.bottom, right: scrollView.contentInset.right)
    }

    /// Reset the height offset when the bounds of the view are set if needed
    private func resetOffsetOnBoundsChangeIfNeeded() {
        if searchBar != nil {
            return
        }

        if !refreshing {
            resetOffset()
        }
    }

    // MARK: - Animation

    func startRefreshAnimation() {
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

    func endRefreshAnimation() {
        refreshInnerImage.layer.removeAllAnimations()
        refreshOuterImage.layer.removeAllAnimations()
    }

    // MARK: - Scroll Events

    /// Track whether we've triggered the haptic.
    /// Defaults to true to prevent the haptic from being fired when the refresh control is initially created
    private var didTriggerHaptic = true

    func didPullDown(_ amount: CGFloat) {
        if refreshing {
            return
        }

        let adjustedAmount = min(pullDownAmountForRefresh, amount)
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

        alpha = adjustedAmount / pullDownAmountForRefresh
    }

    func didEndDraggingAt(_ position: CGFloat) {
        if position > pullDownAmountForRefresh {
            beginRefreshing()
        }
    }

    // MARK: - Refreshing Events

    @objc func podcastsRefreshed() {
        if SyncManager.isUserLoggedIn() {
            DispatchQueue.main.async { [weak self] in
                self?.refreshLabel.text = L10n.refreshControlSyncingPodcasts
            }

            return
        }

        processRefreshCompleted(L10n.refreshControlRefreshComplete)
    }

    @objc func podcastRefreshFailed() {
        processRefreshCompleted(L10n.refreshControlRefreshFailed)
    }

    @objc func syncCompleted() {
        processRefreshCompleted(L10n.refreshControlRefreshComplete)
    }

    @objc func syncFailed() {
        processRefreshCompleted(L10n.refreshControlSyncFailed)
    }

    func processRefreshCompleted(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.refreshLabel.text = message
            self.perform(#selector(self.refreshEndTimerFired), with: nil, afterDelay: 1.0)
        }
    }

    @objc func refreshEndTimerFired() {
        endRefreshing(parentViewVisible)
    }

    private enum RefreshDefaults {
        static let viewHeight: CGFloat = 80
        static let pullDownAmount: CGFloat = 80
    }
}

// MARK: - Calculations

private extension PCRefreshControl {
    func calculateViewHeight() {
        let searchHeight = searchBar != nil ? PCSearchBarController.defaultHeight : 0
        viewHeight = RefreshDefaults.viewHeight + searchHeight
    }

    func calculatePullDownAmount() {
        var amount = RefreshDefaults.pullDownAmount

        if searchBar != nil {
            amount += viewHeight
        }

        pullDownAmountForRefresh = amount
    }
}

// MARK: - Scroll Handling

extension PCRefreshControl {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollAmount = -scrollView.contentOffset.y
        if scrollAmount > 0 {
            didPullDown(scrollAmount)
        } else if scrollAmount < 0 {
            endRefreshing(false)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView) {
        let scrollAmount = -scrollView.contentOffset.y
        if scrollAmount > 0 {
            didEndDraggingAt(scrollAmount)
        }
    }
}
