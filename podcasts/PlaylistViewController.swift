import DifferenceKit
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class PlaylistViewController: PCViewController, TitleButtonDelegate {
    var filter: EpisodeFilter
    var isNewFilter = false

    private var tableRefreshControl: PCRefreshControl?
    private var noEpisodesRefreshControl: PCRefreshControl?

    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    var episodes = [ListEpisode]()

    @IBOutlet var tableView: UITableView! {
        didSet {
            registerCells()
            registerLongPress()
            tableView.allowsMultipleSelectionDuringEditing = true
        }
    }

    @IBOutlet var filterCollectionView: FilterChipCollectionView!

    @IBOutlet var noEpisodesScrollView: UIScrollView! {
        didSet {
            noEpisodesScrollView.backgroundColor = AppTheme.colorForStyle(.primaryUi04)
        }
    }

    @IBOutlet var noEpisodesView: ThemeableView! {
        didSet {
            noEpisodesView.style = .primaryUi02
        }
    }

    @IBOutlet var noEpisodesTitle: ThemeableLabel! {
        didSet {
            noEpisodesTitle.text = L10n.episodeFilterNoEpisodesTitle
        }
    }

    @IBOutlet var noEpisodesDescription: ThemeableLabel! {
        didSet {
            noEpisodesDescription.text = L10n.episodeFilterNoEpisodesMsg
            noEpisodesDescription.style = .primaryText02
        }
    }

    @IBOutlet var noEpisodesIcon: ThemeableImageView! {
        didSet {
            noEpisodesIcon.imageNameFunc = AppTheme.emptyFilterImageName
        }
    }

    init(filter: EpisodeFilter) {
        self.filter = filter

        super.init(nibName: "PlaylistViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet var themeDividerTopAnchor: NSLayoutConstraint!
    @IBOutlet var themeDividerTop: UIView!

    private var titleView: TitleViewWithCollapseButton!
    private var isChipHidden = true
    private var shouldShowChipsAfterMulitSelect = false

    var isMultiSelectEnabled = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.setupNavBar()
                self.tableView.beginUpdates()
                self.tableView.setEditing(self.isMultiSelectEnabled, animated: true)
                self.tableView.updateContentInset(multiSelectEnabled: self.isMultiSelectEnabled)
                self.tableView.endUpdates()

                if self.isMultiSelectEnabled {
                    Analytics.track(.filterMultiSelectEntered)
                    self.multiSelectFooter.setSelectedCount(count: self.selectedEpisodes.count)
                    self.multiSelectFooterBottomConstraint.constant = PlaybackManager.shared.currentEpisode() == nil ? 16 : Constants.Values.miniPlayerOffset + 16
                    self.shouldShowChipsAfterMulitSelect = !self.isChipHidden
                    if !self.isChipHidden {
                        self.hideFilterChips()
                    }
                    if let selectedIndexPath = self.longPressMultiSelectIndexPath {
                        self.tableView.selectIndexPath(selectedIndexPath)
                        self.longPressMultiSelectIndexPath = nil
                    }
                } else {
                    Analytics.track(.filterMultiSelectExited)
                    if self.shouldShowChipsAfterMulitSelect {
                        self.showFilterChips()
                    }
                    self.multiSelectFooter.isHidden = true
                    self.selectedEpisodes.removeAll()
                }
            }
        }
    }

    var multiSelectGestureInProgress = false
    var longPressMultiSelectIndexPath: IndexPath?
    var multiSelectActionInProgress = false
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

    var cellHeights: [IndexPath: CGFloat] = [:]

    // MARK: - View Methods

    override func viewDidLoad() {
        supportsGoogleCast = true
        super.customRightBtn = UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(moreTapped))
        super.customRightBtn?.accessibilityLabel = L10n.accessibilitySortAndOptions

        super.viewDidLoad()

        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.sectionFooterHeight = 0.0
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension

        if let navController = navigationController {
            tableRefreshControl = PCRefreshControl(scrollView: tableView, navBar: navController.navigationBar, source: analyticsSource)
            noEpisodesRefreshControl = PCRefreshControl(scrollView: noEpisodesScrollView, navBar: navController.navigationBar, source: .noFilters)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(navTitleTapped(shortPress:)))
        navigationController?.navigationBar.addGestureRecognizer(tap)

        titleView = TitleViewWithCollapseButton()
        titleView.delegate = self
        navigationItem.titleView = titleView

        themeDividerTopAnchor.constant = isNewFilter ? 52 : 0
        titleView.arrowButton.setExpanded(isNewFilter, animated: false)

        filterCollectionView.chipActionDelegate = self
        filterCollectionView.filter = filter

        isChipHidden = !isNewFilter

        Analytics.track(.filterShown)
    }

    override func viewWillAppear(_ animated: Bool) {
        updateNavTintColor()
        super.viewWillAppear(animated)

        titleView.titleLabel.text = filter.playlistName
        titleView.isAccessibilityElement = true
        titleView.accessibilityLabel = filter.playlistName
        titleView.accessibilityIdentifier = "expandFilter"
        titleView.accessibilityTraits = [.button]

        navigationController?.setNavigationBarHidden(false, animated: true)

        reloadFilterAndRefresh()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBar.shadowImage = UIImage()

        addEventObservers()
        miniPlayerStatusDidChange()

        tableRefreshControl?.parentViewControllerDidAppear()
        noEpisodesRefreshControl?.parentViewControllerDidAppear()

        updateNavTintColor()

        AnalyticsHelper.filterOpened()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllCustomObservers()
        tableRefreshControl?.parentViewControllerDidDisappear()
        noEpisodesRefreshControl?.parentViewControllerDidDisappear()
        navigationController?.navigationBar.shadowImage = nil
    }

    override func handleAppDidEnterBackground() {
        // we don't need to keep our UI up to date while backgrounded, so remove all the notification observers we have
        removeAllCustomObservers()
    }

    override func handleAppWillBecomeActive() {
        refreshEpisodes(animated: true)
        addEventObservers()
    }

    func setupNavBar() {
        navigationItem.titleView = isMultiSelectEnabled ? nil : titleView
        title = isMultiSelectEnabled ? filter.playlistName : nil
        supportsGoogleCast = isMultiSelectEnabled ? false : true
        super.customRightBtn = isMultiSelectEnabled ? UIBarButtonItem(title: L10n.cancel, style: .plain, target: self, action: #selector(cancelTapped)) : UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(moreTapped))
        super.customRightBtn?.accessibilityLabel = isMultiSelectEnabled ? L10n.accessibilityCancelMultiselect : L10n.accessibilitySortAndOptions

        navigationItem.leftBarButtonItem = isMultiSelectEnabled ? UIBarButtonItem(title: L10n.selectAll, style: .done, target: self, action: #selector(selectAllTapped)) : nil
        navigationItem.backBarButtonItem = isMultiSelectEnabled ? nil : UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    // MARK: - Notification Updates

    private func addEventObservers() {
        addCustomObserver(ServerNotifications.podcastsRefreshed, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.opmlImportCompleted, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeDownloaded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackFailed, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.filterChanged, selector: #selector(refreshFilterFromNotification))
        addCustomObserver(Constants.Notifications.upNextEpisodeRemoved, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.upNextEpisodeAdded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.upNextQueueChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeArchiveStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeStarredChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(refreshEpisodesFromNotification))

        addCustomObserver(Constants.Notifications.miniPlayerDidDisappear, selector: #selector(miniPlayerStatusDidChange))
        addCustomObserver(Constants.Notifications.miniPlayerDidAppear, selector: #selector(miniPlayerStatusDidChange))
    }

    private func reloadFilterAndRefresh(animated: Bool = false) {
        if let reloadedFilter = DataManager.sharedManager.findFilter(uuid: filter.uuid) {
            filter = reloadedFilter
            filterCollectionView.filter = reloadedFilter
        }
        refreshEpisodes(animated: animated)
    }

    // MARK: - UIScrollView

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isMultiSelectEnabled else { return }
        let selectedRefreshControl: PCRefreshControl?
        if scrollView == noEpisodesScrollView {
            selectedRefreshControl = noEpisodesRefreshControl
        } else {
            selectedRefreshControl = tableRefreshControl
        }

        selectedRefreshControl?.scrollViewDidScroll(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !isMultiSelectEnabled else { return }
        let selectedRefreshControl: PCRefreshControl?
        if scrollView == noEpisodesScrollView {
            selectedRefreshControl = noEpisodesRefreshControl
        } else {
            selectedRefreshControl = tableRefreshControl
        }

        selectedRefreshControl?.scrollViewDidEndDragging(scrollView)
    }

    @objc func miniPlayerStatusDidChange() {
        updateTableViewContentOffset()
        if isMultiSelectEnabled {
            multiSelectFooterBottomConstraint.constant = PlaybackManager.shared.currentEpisode() == nil ? 16 : Constants.Values.miniPlayerOffset + 16
        }
    }

    private func updateTableViewContentOffset() {
        let multiSelectFooterOffset: CGFloat = isMultiSelectEnabled ? 80 : 0
        let miniPlayerOffset: CGFloat = PlaybackManager.shared.currentEpisode() == nil ? 0 : Constants.Values.miniPlayerOffset
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: miniPlayerOffset + multiSelectFooterOffset, right: 0)
    }

    @objc func moreTapped() {
        Analytics.track(.filterOptionsButtonTapped)

        let optionsPicker = OptionsPicker(title: nil)

        let MultiSelectAction = OptionAction(label: L10n.selectEpisodes, icon: "option-multiselect") { [weak self] in
            Analytics.track(.filterOptionsModalOptionTapped, properties: ["option": "select_episodes"])
            self?.isMultiSelectEnabled = true
        }
        optionsPicker.addAction(action: MultiSelectAction)

        let currentSort = PlaylistSort(rawValue: filter.sortType)?.description ?? ""
        let sortAction = OptionAction(label: L10n.sortBy, secondaryLabel: currentSort, icon: "podcastlist_sort") {
            Analytics.track(.filterOptionsModalOptionTapped, properties: ["option": "sort_by"])
            self.showSortByPicker()
        }
        let editAction = OptionAction(label: L10n.filterOptions, icon: "profile-settings") {
            Analytics.track(.filterOptionsModalOptionTapped, properties: ["option": "filter_options"])
            self.filterOptionsTapped()
        }

        let playAllAction = OptionAction(label: L10n.playAll, icon: "filter_play") { [weak self] in
            guard let self = self else { return }

            Analytics.track(.filterOptionsModalOptionTapped, properties: ["option": "play_all"])
            let playableEpisodeCount = min(ServerSettings.autoAddToUpNextLimit(), self.episodes.count)
            OptionsPickerHelper.playAllWarning(episodeCount: playableEpisodeCount, confirmAction: {
                PlaybackManager.shared.play(filter: self.filter)
            })
        }

        let downloadAllAction = OptionAction(label: L10n.downloadAll, icon: "filter_downloaded") { [weak self] in
            guard let self = self else { return }
            Analytics.track(.filterOptionsModalOptionTapped, properties: ["option": "download_all"])

            let downloadableCount = self.downloadableCount(listEpisodes: self.episodes)
            let downloadLimitExceeded = downloadableCount > Constants.Limits.maxBulkDownloads
            let actualDownloadCount = downloadLimitExceeded ? Constants.Limits.maxBulkDownloads : downloadableCount
            if actualDownloadCount == 0 { return }
            let downloadText = L10n.downloadCountPrompt(actualDownloadCount)
            let downloadAction = OptionAction(label: downloadText, icon: nil) { [weak self] in
                self?.downloadAll()
            }

            let confirmPicker = OptionsPicker(title: nil)
            var warningMessage = downloadLimitExceeded ? L10n.bulkDownloadMax : ""

            if NetworkUtils.shared.isConnectedToWifi() {
                confirmPicker.addDescriptiveActions(title: L10n.downloadAll, message: warningMessage, icon: "filter_downloaded", actions: [downloadAction])
            } else {
                downloadAction.destructive = true

                let queueAction = OptionAction(label: L10n.queueForLater, icon: nil) {
                    self.queueAll()
                }

                if !Settings.mobileDataAllowed() {
                    warningMessage = L10n.downloadDataWarning + "\n" + warningMessage
                }

                confirmPicker.addDescriptiveActions(title: L10n.notOnWifi, message: warningMessage, icon: "option-alert", actions: [downloadAction, queueAction])
            }
            confirmPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
        }

        optionsPicker.addAction(action: sortAction)
        optionsPicker.addAction(action: playAllAction)
        optionsPicker.addAction(action: downloadAllAction)
        optionsPicker.addAction(action: editAction)

        optionsPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }

    func showSortByPicker() {
        let optionsPicker = OptionsPicker(title: L10n.sortBy.localizedUppercase)

        addSortAction(to: optionsPicker, sortOrder: .newestToOldest)
        addSortAction(to: optionsPicker, sortOrder: .oldestToNewest)
        addSortAction(to: optionsPicker, sortOrder: .shortestToLongest)
        addSortAction(to: optionsPicker, sortOrder: .longestToShortest)

        optionsPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }

    private func addSortAction(to optionPicker: OptionsPicker, sortOrder: PlaylistSort) {
        let action = OptionAction(label: sortOrder.description, selected: filter.sortType == sortOrder.rawValue) {
            Analytics.track(.filterSortByChanged, properties: ["sort_order": sortOrder])
            self.filter.sortType = sortOrder.rawValue
            self.saveFilter()
        }
        optionPicker.addAction(action: action)
    }

    @objc func filterOptionsTapped() {
        let filterEditController = FilterEditOptionsViewController()
        filterEditController.filterToEdit = filter
        navigationController?.pushViewController(filterEditController, animated: true)
    }

    func saveFilter() {
        filter.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(filter: filter)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged, object: filter)
    }

    override func handleThemeChanged() {
        tableView.reloadData()
        filterCollectionView.reloadData()
        updateNavTintColor()
        noEpisodesScrollView.backgroundColor = AppTheme.colorForStyle(.primaryUi04)
        noEpisodesIcon.tintColor = ThemeColor.primaryIcon02()
    }

    private func updateNavTintColor() {
        let filterColor = filter.playlistColor()
        let titleColor = ThemeColor.filterText01(filterColor: filterColor)
        let iconColor = ThemeColor.filterIcon01(filterColor: filterColor)
        let backgroundColor = ThemeColor.filterUi01(filterColor: filterColor)
        changeNavTint(titleColor: titleColor, iconsColor: iconColor, backgroundColor: backgroundColor)
        titleView.setTintColor(newColor: iconColor)
        themeDividerTop.backgroundColor = ThemeColor.filterUi04(filterColor: filterColor)

        filterCollectionView.backgroundColor = backgroundColor
    }

    func arrowTapped() {
        toggleFilterChipHideShow()
    }

    @objc func navTitleTapped(shortPress: UITapGestureRecognizer) {
        guard !isMultiSelectEnabled else { return }

        toggleFilterChipHideShow()
    }

    private func toggleFilterChipHideShow() {
        if !isChipHidden {
            hideFilterChips()
        } else {
            showFilterChips()
        }
    }

    func hideFilterChips() {
        isChipHidden = true
        titleView.arrowButton.setExpanded(false)
        themeDividerTopAnchor.constant = 0
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.titleView.accessibilityHint = L10n.accessibilityShowFilterDetails
        })
    }

    func showFilterChips() {
        isChipHidden = false
        titleView.arrowButton.setExpanded(true)
        themeDividerTopAnchor.constant = 52
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.titleView.accessibilityHint = L10n.accessibilityHideFilterDetails
        })
    }

    // MARK: - Refresh

    @objc private func refreshFilterFromNotification() {
        updateNavTintColor()
        reloadFilterAndRefresh(animated: true)
    }

    @objc private func refreshEpisodesFromNotification() {
        refreshEpisodes(animated: true)
    }

    func refreshEpisodes(animated: Bool) {
        let refreshOperation = PlaylistRefreshOperation(tableView: tableView, filter: filter) { [weak self] newData in
            guard let strongSelf = self else { return }

            strongSelf.tableView.isHidden = (newData.count == 0)
            if animated {
                let oldData = strongSelf.episodes
                let changeSet = StagedChangeset(source: oldData, target: newData)
                strongSelf.tableView.reload(using: changeSet, with: .none, setData: { data in
                    strongSelf.episodes = data
                })
            } else {
                strongSelf.episodes = newData
                strongSelf.tableView.reloadData()
            }
            strongSelf.refreshMultiSelectEpisodes()
        }

        operationQueue.addOperation(refreshOperation)
    }

    // MARK: - Long press helpers

    func archiveAll(startingAt: Episode) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            if self.episodes.count == 0 { return }

            var haveFoundFirst = false
            for listEpisode in self.episodes {
                if !haveFoundFirst, listEpisode.episode.uuid != startingAt.uuid { continue }

                haveFoundFirst = true
                if listEpisode.episode.archived { continue }

                EpisodeManager.archiveEpisode(episode: listEpisode.episode, fireNotification: false)
            }

            self.refreshEpisodes(animated: true)
        }
    }

    func downloadAll() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            if self.episodes.count == 0 { return }

            self.downloadItems(allEpisodes: self.episodes)
        }
    }

    func queueAll() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            if self.episodes.count == 0 { return }
            self.queueItems(allEpisodes: self.episodes)
        }
    }

    func queueItems(allEpisodes: [ListEpisode]) {
        var queuedEpisodes = 0
        for listEpisode in allEpisodes {
            if listEpisode.episode.downloading() || listEpisode.episode.downloaded(pathFinder: DownloadManager.shared) || listEpisode.episode.queued() {
                continue
            }

            DownloadManager.shared.queueForLaterDownload(episodeUuid: listEpisode.episode.uuid, fireNotification: true, autoDownloadStatus: .notSpecified)

            queuedEpisodes += 1
            if queuedEpisodes == Constants.Limits.maxBulkDownloads {
                return
            }
        }
    }

    func downloadItems(allEpisodes: [ListEpisode]) {
        var queuedEpisodes = 0
        for listEpisode in allEpisodes {
            if listEpisode.episode.downloading() || listEpisode.episode.downloaded(pathFinder: DownloadManager.shared) || listEpisode.episode.queued() {
                continue
            }

            DownloadManager.shared.addToQueue(episodeUuid: listEpisode.episode.uuid, fireNotification: true, autoDownloadStatus: .notSpecified)
            queuedEpisodes += 1
            if queuedEpisodes == Constants.Limits.maxBulkDownloads {
                return
            }
        }
    }

    func downloadableCount(listEpisodes: [ListEpisode]) -> Int {
        if listEpisodes.count == 0 { return 0 }
        var count = 0

        for listEpisode in listEpisodes {
            if !listEpisode.episode.downloaded(pathFinder: DownloadManager.shared), !listEpisode.episode.downloading(), !listEpisode.episode.queued() {
                count += 1
            }
        }
        return count
    }
}

// MARK: - Analytics

extension PlaylistViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .filters
    }
}

// MARK: - Autoplay
extension PlaylistViewController: PlaylistAutoplay {
    var playlist: EpisodesDataManager.Playlist {
        .filter(uuid: filter.uuid)
    }
}
