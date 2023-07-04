import DifferenceKit
import PocketCastsDataModel
import PocketCastsServer
import UIKit

class StarredViewController: PCViewController {
    private let episodesDataManager = EpisodesDataManager()

    @IBOutlet var starredTable: UITableView! {
        didSet {
            starredTable.applyInsetForMiniPlayer()
            registerCells()
            starredTable.estimatedRowHeight = 80
            starredTable.rowHeight = UITableView.automaticDimension
            starredTable.allowsMultipleSelectionDuringEditing = true
            registerLongPress()
        }
    }

    @IBOutlet var noEpisodesIcon: UIImageView! {
        didSet {
            noEpisodesIcon.tintColor = ThemeColor.primaryIcon02()
        }
    }

    @IBOutlet var noEpisodesTitle: ThemeableLabel! {
        didSet {
            noEpisodesTitle.text = L10n.profileStarredNoEpisodesTitle
        }
    }

    @IBOutlet var noEpisodesDescription: ThemeableLabel! {
        didSet {
            noEpisodesDescription.style = .primaryText02
            noEpisodesDescription.text = L10n.profileStarredNoEpisodesDesc
        }
    }

    @IBOutlet var loadingIndicator: UIActivityIndicatorView!

    var episodes = [ListEpisode]()
    private let refreshQueue = OperationQueue()
    var cellHeights: [IndexPath: CGFloat] = [:]
    var isMultiSelectEnabled = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.setupNavBar()
                self.starredTable.beginUpdates()
                self.starredTable.setEditing(self.isMultiSelectEnabled, animated: true)
                self.starredTable.updateContentInset(multiSelectEnabled: self.isMultiSelectEnabled)
                self.starredTable.endUpdates()

                if self.isMultiSelectEnabled {
                    Analytics.track(.starredMultiSelectEntered)
                    self.multiSelectFooter.setSelectedCount(count: self.selectedEpisodes.count)
                    self.multiSelectFooterBottomConstraint.constant = PlaybackManager.shared.currentEpisode() == nil ? 16 : Constants.Values.miniPlayerOffset + 16
                    if let selectedIndexPath = self.longPressMultiSelectIndexPath {
                        self.starredTable.selectIndexPath(selectedIndexPath)
                        self.longPressMultiSelectIndexPath = nil
                    }
                } else {
                    Analytics.track(.starredMultiSelectExited)
                    self.selectedEpisodes.removeAll()
                }
            }
        }
    }

    var multiSelectGestureInProgress = false
    var longPressMultiSelectIndexPath: IndexPath?
    @IBOutlet var multiSelectFooter: MultiSelectFooterView! {
        didSet {
            multiSelectFooter.delegate = self
        }
    }

    @IBOutlet var multiSelectFooterBottomConstraint: NSLayoutConstraint!

    var selectedEpisodes = [ListEpisode]() {
        didSet {
            multiSelectFooter.setSelectedCount(count: selectedEpisodes.count)
            updateSelectAllBtn()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshQueue.maxConcurrentOperationCount = 1
        title = L10n.statusStarred
        setupNavBar()
        if SyncManager.isUserLoggedIn() {
            refreshEpisodesFromServer(animated: false)
        } else {
            refreshEpisodesFromDatabase(animated: false)
        }
        addEventObservers()
        Analytics.track(.starredShown)
    }

    func refreshEpisodesFromServer(animated: Bool) {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        refreshQueue.addOperation {
            ApiServerHandler.shared.retrieveStarred { episodes in
                guard let episodes = episodes else {
                    DispatchQueue.main.sync {
                        self.loadingIndicator.stopAnimating()
                    }

                    return
                }

                let oldData = self.episodes
                var newData = [ListEpisode]()
                for episode in episodes {
                    newData.append(ListEpisode(episode: episode, tintColor: AppTheme.appTintColor(), isInUpNext: PlaybackManager.shared.inUpNext(episode: episode)))
                }

                DispatchQueue.main.sync { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.loadingIndicator.stopAnimating()
                    strongSelf.starredTable.isHidden = (newData.count == 0)
                    if animated {
                        let changeSet = StagedChangeset(source: oldData, target: newData)
                        strongSelf.starredTable.reload(using: changeSet, with: .none, setData: { data in
                            strongSelf.episodes = data
                        })
                    } else {
                        strongSelf.episodes = newData
                        strongSelf.starredTable.reloadData()
                    }
                }
            }
        }
    }

    func refreshEpisodesFromDatabase(animated: Bool) {
        refreshQueue.addOperation { [weak self] in
            guard let self else { return }
            let oldData = self.episodes
            let newData = self.episodesDataManager.starredEpisodes()

            DispatchQueue.main.sync {
                self.starredTable.isHidden = (newData.count == 0)
                if animated {
                    let changeSet = StagedChangeset(source: oldData, target: newData)
                    self.starredTable.reload(using: changeSet, with: .none, setData: { data in
                        self.episodes = data
                    })
                } else {
                    self.episodes = newData
                    self.starredTable.reloadData()
                }
            }
        }
    }

    private func addEventObservers() {
        addCustomObserver(Constants.Notifications.episodeStarredChanged, selector: #selector(refreshEpisodesFromNotification(notification:)))
        addCustomObserver(Constants.Notifications.episodeDownloaded, selector: #selector(refreshEpisodesFromNotification(notification:)))
        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(refreshEpisodesFromNotification(notification:)))
        addCustomObserver(Constants.Notifications.episodeArchiveStatusChanged, selector: #selector(refreshEpisodesFromNotification(notification:)))
        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(refreshEpisodesFromNotification(notification:)))
        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(refreshEpisodesFromNotification(notification:)))
        addCustomObserver(Constants.Notifications.upNextEpisodeRemoved, selector: #selector(refreshEpisodesFromNotification(notification:)))
        addCustomObserver(Constants.Notifications.upNextEpisodeAdded, selector: #selector(refreshEpisodesFromNotification(notification:)))
        addCustomObserver(Constants.Notifications.upNextQueueChanged, selector: #selector(refreshEpisodesFromNotification(notification:)))
    }

    @objc private func refreshEpisodesFromNotification(notification: Notification) {
        refreshEpisodesFromDatabase(animated: true)
    }

    deinit {
        removeAllCustomObservers()
    }

    func setupNavBar() {
        super.customRightBtn = isMultiSelectEnabled ? UIBarButtonItem(title: L10n.cancel, style: .plain, target: self, action: #selector(cancelTapped)) : UIBarButtonItem(title: L10n.select, style: .plain, target: self, action: #selector(selectTapped))
        super.customRightBtn?.accessibilityLabel = isMultiSelectEnabled ? L10n.accessibilityCancelMultiselect : L10n.select

        navigationItem.leftBarButtonItem = isMultiSelectEnabled ? UIBarButtonItem(title: L10n.selectAll, style: .done, target: self, action: #selector(selectAllTapped)) : nil
        navigationItem.backBarButtonItem = isMultiSelectEnabled ? nil : UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}

// MARK: - Analytics

extension StarredViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .starred
    }
}
