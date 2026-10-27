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

    private var tableTopBelowHeader: NSLayoutConstraint?
    private var tableTopAtEdge: NSLayoutConstraint?

    lazy var playbackManager = PlaybackManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpHeader()

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
        updateHeader()
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
        let currentChapter = PlaybackManager.shared.currentChapters

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
        updateHeader()
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
    }

    /// The header sits above the table instead of being its section header, so the chapters
    /// scroll up to its bottom edge and not under it, and it needs no fill to hide them.
    private func setUpHeader() {
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        for constraint in view.constraints where constraint.firstItem === chaptersTable && constraint.firstAttribute == .top {
            constraint.isActive = false
        }
        tableTopBelowHeader = chaptersTable.topAnchor.constraint(equalTo: header.bottomAnchor)
        tableTopAtEdge = chaptersTable.topAnchor.constraint(equalTo: view.topAnchor)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        updateHeaderVisibility()
    }

    private func updateHeader() {
        header.update()
        updateHeaderVisibility()
    }

    private func updateHeaderVisibility() {
        header.isHidden = !shouldShowDeselectChaptersHeader
        tableTopBelowHeader?.isActive = !header.isHidden
        tableTopAtEdge?.isActive = header.isHidden
    }

    func updateSize() {
        /// Forces headers & cells to recalculate their heights
        chaptersTable.beginUpdates()
        chaptersTable.endUpdates()
    }
}
