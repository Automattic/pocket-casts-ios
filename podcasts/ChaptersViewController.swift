import UIKit
import PocketCastsServer

class ChaptersViewController: PlayerItemViewController {
    var isTogglingChapters = false

    var numberOfDeselectedChapters = 0

    /// The row whose generated chapter is currently being resolved to a real
    /// playback position via fingerprinting (shows a spinner). Nil when idle.
    /// Drives the per-row spinner from `cellForRowAt` so it survives cell reuse.
    var resolvingIndexPath: IndexPath?

    @IBOutlet var chaptersTable: UITableView! {
        didSet {
            registerCells()
            chaptersTable.backgroundView = nil
        }
    }

    private(set) lazy var header: ChaptersHeader = {
        let header = ChaptersHeader()
        header.delegate = self
        return header
    }()

    lazy var playbackManager = PlaybackManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        chaptersTable.sectionHeaderTopPadding = 0

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (controller: ChaptersViewController, _) in
            controller.updateSize()
        }
    }

    override func willBeAddedToPlayer() {
        if usesLargeScreenStyle {
            additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        }
        header.usesLargeScreenStyle = usesLargeScreenStyle
        updateColors()
        header.update()
        addObservers()
    }

    override func willBeRemovedFromPlayer() {
        removeAllCustomObservers()
        // Drop any in-flight chapter resolve so a backgrounded list can't seek later.
        FingerprintTimingManager.shared.cancelPendingChapterResolve()
        resolvingIndexPath = nil
    }

    override func themeDidChange() {
        update()
    }

    func scrollToCurrentlyPlayingChapter(animated: Bool) {
        let currentChapter = PlaybackManager.shared.currentChapters()

        guard let index = playbackManager.index(for: currentChapter) else {
            return
        }

        // scroll far enough to at least see the current chapter + a few more
        chaptersTable.scrollToRow(at: IndexPath(item: index, section: 0), at: .middle, animated: animated)
    }

    private func addObservers() {
        addCustomObserver(Constants.Notifications.episodeDurationChanged, selector: #selector(update))
        addCustomObserver(Constants.Notifications.playbackStarted, selector: #selector(update))
        addCustomObserver(Constants.Notifications.playbackPaused, selector: #selector(update))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(update))
        addCustomObserver(Constants.Notifications.podcastChaptersDidUpdate, selector: #selector(update))
        addCustomObserver(Constants.Notifications.podcastChapterChanged, selector: #selector(update))
        addCustomObserver(UIApplication.willEnterForegroundNotification, selector: #selector(update))
        addCustomObserver(ServerNotifications.iapPurchaseCompleted, selector: #selector(enableOrDisableChapterSelectionIfUserJustPurchased))
    }

    @objc private func update() {
        chaptersTable.reloadData()
        updateColors()
        header.update()
    }

    @objc private func enableOrDisableChapterSelectionIfUserJustPurchased() {
        DispatchQueue.main.async { [weak self] in
            self?.isTogglingChapters = PaidFeature.deselectChapters.isUnlocked ? true : false
            self?.header.isTogglingChapters = self?.isTogglingChapters ?? false
            self?.header.update()
            self?.chaptersTable.reloadSections([0], with: .automatic)
        }
    }

    private func updateColors() {
        let backgroundColor = usesLargeScreenStyle ? .clear : PlayerColorHelper.playerBackgroundColor01()
        view.backgroundColor = backgroundColor
        chaptersTable.backgroundColor = backgroundColor
        updateHeaderColor()
    }

    /// The header sticks to the top, so it's filled to hide the chapters under it. Over the large
    /// screen player background, it's only filled once there are chapters to hide.
    func updateHeaderColor() {
        let color = PlayerColorHelper.playerBackgroundColor01()
        guard usesLargeScreenStyle else {
            header.backgroundColor = color
            return
        }
        let scrolledDistance = chaptersTable.contentOffset.y + chaptersTable.adjustedContentInset.top
        header.backgroundColor = color.withAlphaComponent(min(1, max(0, scrolledDistance / 16)))
    }

    func updateSize() {
        /// Forces headers & cells to recalculate their heights
        chaptersTable.beginUpdates()
        chaptersTable.endUpdates()
    }
}
