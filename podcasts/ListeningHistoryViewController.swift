import DifferenceKit
import PocketCastsDataModel
import PocketCastsServer
import UIKit

class ListeningHistoryViewController: PCViewController {
    var episodes = [ArraySection<String, ListEpisode>]()
    private let operationQueue = OperationQueue()
    var cellHeights: [IndexPath: CGFloat] = [:]

    @IBOutlet var listeningHistoryTable: UITableView! {
        didSet {
            registerCells()
            listeningHistoryTable.updateContentInset(multiSelectEnabled: false)
            listeningHistoryTable.estimatedRowHeight = 80
            listeningHistoryTable.rowHeight = UITableView.automaticDimension
            listeningHistoryTable.allowsMultipleSelection = true
            listeningHistoryTable.allowsMultipleSelectionDuringEditing = true
            registerLongPress()
        }
    }

    var isMultiSelectEnabled = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.setupNavBar()
                self.listeningHistoryTable.beginUpdates()
                self.listeningHistoryTable.setEditing(self.isMultiSelectEnabled, animated: true)
                self.listeningHistoryTable.updateContentInset(multiSelectEnabled: self.isMultiSelectEnabled)
                self.listeningHistoryTable.endUpdates()

                if self.isMultiSelectEnabled {
                    Analytics.track(.listeningHistoryMultiSelectEntered)
                    self.multiSelectFooter.setSelectedCount(count: self.selectedEpisodes.count)
                    self.multiSelectFooterBottomConstraint.constant = PlaybackManager.shared.currentEpisode() == nil ? 16 : Constants.Values.miniPlayerOffset + 16
                    if let selectedIndexPath = self.longPressMultiSelectIndexPath {
                        self.listeningHistoryTable.selectIndexPath(selectedIndexPath)
                        self.longPressMultiSelectIndexPath = nil
                    }
                } else {
                    Analytics.track(.listeningHistoryMultiSelectExited)
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

        operationQueue.maxConcurrentOperationCount = 1
        title = L10n.listeningHistory
        refreshEpisodes(animated: false)

        setupNavBar()

        Analytics.track(.listeningHistoryShown)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        addCustomObserver(Constants.Notifications.episodeDownloaded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackFailed, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.upNextEpisodeRemoved, selector: #selector(upNextChanged))
        addCustomObserver(Constants.Notifications.upNextEpisodeAdded, selector: #selector(upNextChanged))
        addCustomObserver(Constants.Notifications.upNextQueueChanged, selector: #selector(upNextChanged))
        addCustomObserver(Constants.Notifications.episodeArchiveStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeStarredChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(refreshEpisodesFromNotification))
    }

    @objc private func refreshEpisodesFromNotification() {
        refreshEpisodes(animated: true)
    }

    @objc private func upNextChanged() {
        listeningHistoryTable.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        removeAllCustomObservers()
    }

    override func handleThemeChanged() {
        listeningHistoryTable.reloadData()
    }

    // Listening history query ArraySection<String, ListEpisode>
    func refreshEpisodes(animated: Bool) {
        operationQueue.addOperation {
            let oldData = self.episodes
            let newData = DatabaseQueries.shared.listeningHistoryEpisodes()

            DispatchQueue.main.sync { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.listeningHistoryTable.isHidden = (newData.count == 0)
                if animated {
                    let changeSet = StagedChangeset(source: oldData, target: newData)
                    strongSelf.listeningHistoryTable.reload(using: changeSet, with: .none, setData: { data in
                        strongSelf.episodes = data
                    })
                } else {
                    strongSelf.episodes = newData
                    strongSelf.listeningHistoryTable.reloadData()
                }
            }
        }
    }

    @objc func clearTapped() {
        let optionPicker = OptionsPicker(title: "")
        let clearAllAction = OptionAction(label: L10n.historyClearAll, icon: nil, action: {
            Analytics.track(.listeningHistoryCleared)
            DataManager.sharedManager.clearAllEpisodePlayInteractions()
            if SyncManager.isUserLoggedIn() { ServerSettings.setLastClearHistoryDate(Date()) }
            self.refreshEpisodes(animated: true)

        })
        optionPicker.addDescriptiveActions(title: L10n.historyClearAllDetails, message: L10n.historyClearAllDetailsMsg, icon: "option-cleanup", actions: [clearAllAction])
        optionPicker.show(statusBarStyle: preferredStatusBarStyle)
    }

    func setupNavBar() {
        super.customRightBtn = isMultiSelectEnabled ? UIBarButtonItem(title: L10n.cancel, style: .plain, target: self, action: #selector(cancelTapped)) : UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(menuTapped))
        super.customRightBtn?.accessibilityLabel = isMultiSelectEnabled ? L10n.accessibilityCancelMultiselect : L10n.accessibilityMoreActions

        navigationItem.leftBarButtonItem = isMultiSelectEnabled ? UIBarButtonItem(title: L10n.selectAll, style: .done, target: self, action: #selector(selectAllTapped)) : nil
        navigationItem.backBarButtonItem = isMultiSelectEnabled ? nil : UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    @objc private func menuTapped(_ sender: UIBarButtonItem) {
        Analytics.track(.listeningHistoryOptionsButtonTapped)

        let optionsPicker = OptionsPicker(title: nil)

        let MultiSelectAction = OptionAction(label: L10n.selectEpisodes, icon: "option-multiselect") { [weak self] in
            Analytics.track(.listeningHistoryOptionsModalOptionTapped, properties: ["option": "select_episodes"])
            self?.isMultiSelectEnabled = true
        }
        optionsPicker.addAction(action: MultiSelectAction)

        let clearAction = OptionAction(label: L10n.historyClearAllDetails, icon: "option-cleanup") { [weak self] in
            Analytics.track(.listeningHistoryOptionsModalOptionTapped, properties: ["option": "clear_history"])
            self?.clearTapped()
        }
        optionsPicker.addAction(action: clearAction)

        optionsPicker.show(statusBarStyle: preferredStatusBarStyle)
    }
}

// MARK: - Analytics

extension ListeningHistoryViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .listeningHistory
    }
}

extension ListeningHistoryViewController: Autoplay {
    var provider: DatabaseQueries.Section {
        .listeningHistory
    }
}
