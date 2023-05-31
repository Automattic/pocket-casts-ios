import UIKit

class ChaptersViewController: PlayerItemViewController {
    @IBOutlet var chaptersTable: UITableView! {
        didSet {
            registerCells()
            chaptersTable.backgroundView = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
        guard let currentChapter = PlaybackManager.shared.currentChapter() else { return }

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
    }

    @objc private func update() {
        chaptersTable.reloadData()
        updateColors()
    }

    private func updateColors() {
        view.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
        chaptersTable.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
    }
}
