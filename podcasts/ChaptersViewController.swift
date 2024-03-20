import UIKit
import PocketCastsServer

class ChaptersViewController: PlayerItemViewController {
    var isTogglingChapters = false

    var numberOfDeselectedChapters = 0

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

    lazy var playbackManager: PlaybackManager = PlaybackManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        chaptersTable.sectionHeaderTopPadding = 0
    }

    override func willBeAddedToPlayer() {
        updateColors()
        addObservers()
    }

    override func willBeRemovedFromPlayer() {
        removeAllCustomObservers()
    }

    override func themeDidChange() {
        update()
    }

    func scrollToCurrentlyPlayingChapter(animated: Bool) {
        let currentChapter = PlaybackManager.shared.currentChapters()

        // scroll far enough to at least see the current chapter + a few more
        chaptersTable.scrollToRow(at: IndexPath(item: currentChapter.index, section: 0), at: .middle, animated: animated)
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
        view.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
        chaptersTable.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
    }
}
