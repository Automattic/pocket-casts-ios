import DifferenceKit
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit
import UIDeviceIdentifier

protocol PodcastActionsDelegate: AnyObject {
    func isSummaryExpanded() -> Bool
    func setSummaryExpanded(expanded: Bool)
    func isDescriptionExpanded() -> Bool
    func setDescriptionExpanded(expanded: Bool)

    func tableView() -> UITableView
    func displayedPodcast() -> Podcast?
    func episodeCount() -> Int
    func archivedEpisodeCount() -> Int

    func manageSubscriptionTapped()
    func settingsTapped()
    func folderTapped()
    func subscribe()
    func unsubscribe()
    func refreshArtwork(fromRect: CGRect, inView: UIView)
    func searchEpisodes(query: String)
    func clearSearch()
    func toggleShowArchived()
    func showingArchived() -> Bool
    func archiveAllTapped(playedOnly: Bool)
    func unarchiveAllTapped()
    func downloadAllTapped()
    func queueAllTapped()
    func downloadableEpisodeCount(items: [ListItem]?) -> Int

    func didActivateSearch()

    func enableMultiSelect()

    var podcastRatingViewModel: PodcastRatingViewModel { get }
    func showBookmarks()
}

class PodcastViewController: FakeNavViewController, PodcastActionsDelegate, SyncSigninDelegate, MultiSelectActionDelegate {
    var podcast: Podcast?
    var episodeInfo = [ArraySection<String, ListItem>]()
    var uuidsThatMatchSearch = [String]()
    var featuredPodcast = false
    var listUuid: String?
    var summaryExpanded = false
    var descriptionExpanded = false

    var searchController: EpisodeListSearchController?

    var cellHeights: [IndexPath: CGFloat] = [:]

    var podcastRatingViewModel = PodcastRatingViewModel()

    private var podcastInfo: PodcastInfo?
    var loadingPodcastInfo = false
    lazy var isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    @IBOutlet var episodesTableTopConstraint: NSLayoutConstraint!

    @IBOutlet var episodesTable: UITableView! {
        didSet {
            registerCells()
            registerLongPress()
            episodesTable.rowHeight = UITableView.automaticDimension
            episodesTable.estimatedRowHeight = 80.0
            episodesTable.allowsMultipleSelectionDuringEditing = true
            episodesTable.sectionHeaderTopPadding = 0
        }
    }

    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var loadingBgView: UIView! {
        didSet {
            loadingBgView.backgroundColor = AppTheme.defaultPodcastBackgroundColor()
        }
    }

    @IBOutlet var loadingImageBg: UIView! {
        didSet {
            loadingImageBg.backgroundColor = ThemeColor.primaryUi05()
        }
    }

    var isMultiSelectEnabled = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.episodesTable.beginUpdates()
                self.episodesTable.setEditing(self.isMultiSelectEnabled, animated: true)
                if self.episodesTable.numberOfSections > 0 {
                    self.episodesTable.reloadSections([0], with: .none)
                }
                self.episodesTable.endUpdates()
                if self.isMultiSelectEnabled {
                    if self.selectedEpisodes.count == 0, self.longPressMultiSelectIndexPath == nil, !self.multiSelectGestureInProgress {
                        self.tableView().scrollToRow(at: IndexPath(row: NSNotFound, section: PodcastViewController.allEpisodesSection), at: .top, animated: true)
                    }
                    self.multiSelectFooter.setSelectedCount(count: self.selectedEpisodes.count)
                    if let selectedIndexPath = self.longPressMultiSelectIndexPath {
                        self.tableView().selectIndexPath(selectedIndexPath)
                        self.longPressMultiSelectIndexPath = nil
                    }
                    if let podcast = self.podcast {
                        let podcastBgColor = ColorManager.backgroundColorForPodcast(podcast)
                        self.multiSelectHeaderView.backgroundColor = ThemeColor.podcastUi05(podcastColor: podcastBgColor)
                        self.multiSelectCancelBtn.setTitleColor(ThemeColor.contrast01(), for: .normal)
                        self.multiSelectAllBtn.setTitleColor(ThemeColor.contrast01(), for: .normal)
                        self.updateSelectAllBtn()
                        self.multiSelectFooterBottomConstraint.constant = PlaybackManager.shared.currentEpisode() == nil ? 16 : Constants.Values.miniPlayerOffset + 16
                        self.multiSelectHeaderView.isHidden = false
                        self.view.bringSubviewToFront(self.multiSelectHeaderView)

                        // Adjusts multiSelectHeaderView based on screen width
                        self.setMultiSelectHeaderViewConstraint()

                    }
                } else {
                    self.multiSelectHeaderView.isHidden = true
                    self.selectedEpisodes.removeAll()
                }
                self.searchController?.isOverflowButtonEnabled = !self.isMultiSelectEnabled
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

    @IBOutlet var multiSelectCancelBtn: UIButton! {
        didSet {
            multiSelectCancelBtn.setTitle(L10n.cancel, for: .normal)
        }
    }

    @IBOutlet var multiSelectAllBtn: UIButton!
    @IBOutlet var multiSelectHeaderView: ThemeableView!
    private let operationQueue = OperationQueue()

    // Constraint to adjust multiSelectHeader based on device size
    @IBOutlet weak var multiSelectHeaderViewConstraint: NSLayoutConstraint!

    private func setMultiSelectHeaderViewConstraint() {
        let screenWidth = UIScreen.main.bounds.width
        var setConstant: Double

        switch screenWidth {
        /* iPod Touch (320) to iPhone SE 3rd gen (375) and
         iPad Mini 4 (760) to iPad 6th Gen (1024) */
        case 320...380, 760...1024:
            setConstant = 65.0
        /* Covers most modern devices (380+ width),
         from iPhone 6 Plus (414) to iPhone 14 Pro Max (430) */
        default:
            setConstant = 90.0
        }

        self.multiSelectHeaderViewConstraint.constant = setConstant
    }

    static let headerSection = 0
    static let allEpisodesSection = 1

    private var isSearching = false

    init(podcast: Podcast) {
        self.podcast = podcast

        // show the expaned view for unsubscribed podcasts, as well as paid podcasts that have expired and you no longer have access to play/download
        summaryExpanded = !podcast.isSubscribed() || (podcast.isPaid && podcast.licensing == PodcastLicensing.deleteEpisodesAfterExpiry.rawValue && (SubscriptionHelper.subscriptionForPodcast(uuid: podcast.uuid)?.isExpired() ?? false))

        AnalyticsHelper.podcastOpened(uuid: podcast.uuid)
        podcastRatingViewModel.update(uuid: podcast.uuid)

        super.init(nibName: "PodcastViewController", bundle: nil)
    }

    init(podcastInfo: PodcastInfo, existingImage: UIImage?) {
        if let uuid = podcastInfo.uuid, let existingPodcast = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) {
            podcast = existingPodcast
            summaryExpanded = !existingPodcast.isSubscribed()
        } else {
            self.podcastInfo = podcastInfo
            summaryExpanded = true
        }

        if let uuid = podcastInfo.uuid {
            podcastRatingViewModel.update(uuid: uuid)
            AnalyticsHelper.podcastOpened(uuid: uuid)
        }

        super.init(nibName: "PodcastViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        operationQueue.cancelAllOperations()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        closeTapped = { [weak self] in
            _ = self?.navigationController?.popViewController(animated: true)
        }

        searchController = EpisodeListSearchController()
        searchController?.podcastDelegate = self

        operationQueue.maxConcurrentOperationCount = 1
        scrollPointToChangeTitle = 38
        addRightAction(image: UIImage(named: "podcast-share"), accessibilityLabel: L10n.share, action: #selector(shareTapped(_:)))
        addGoogleCastBtn()
        loadPodcastInfo()
        updateColors()
        updateTopConstraintForiPhone14Pro()

        NotificationCenter.default.addObserver(self, selector: #selector(podcastUpdated(_:)), name: Constants.Notifications.podcastUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(folderChanged(_:)), name: Constants.Notifications.folderChanged, object: nil)
    }

    private func updateTopConstraintForiPhone14Pro() {
        // Retrieve the name of the device
        var deviceName = UIDeviceHardware.platformString()

        #if targetEnvironment(simulator)
        // If we're running in the simulator, grab the model that we're simulating
        if let simulatorIdentifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            deviceName = UIDeviceHardware.platformString(forType: simulatorIdentifier)
        }
        #endif

        if deviceName.startsWith(string: "iPhone 14 Pro") {
            // On iPhone 14 Pro and iPhone 14 Pro Max there's a space
            // between the nav bar and the content
            // Here we change the table top constraint to take into account that
            // See: https://github.com/Automattic/pocket-casts-ios/issues/327
            episodesTableTopConstraint.constant = -5
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Load the ratings even if we've already started loading them to cover all other potential view states
        // The view model will ignore extra calls
        if let uuid = [podcast?.uuid, podcastInfo?.uuid].compactMap({ $0 }).first {
            podcastRatingViewModel.update(uuid: uuid)
        }

        updateColors()
    }

    private var hasAppearedAlready = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        addCustomObserver(Constants.Notifications.podcastColorsDownloaded, selector: #selector(colorsDidDownload(_:)))
        updateColors()

        addCustomObserver(Constants.Notifications.episodeArchiveStatusChanged, selector: #selector(refreshEpisodes))
        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(refreshEpisodes))
        addCustomObserver(Constants.Notifications.episodeStarredChanged, selector: #selector(refreshEpisodes))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(refreshEpisodes))
        addCustomObserver(Constants.Notifications.playbackStarted, selector: #selector(hideSearchKeyboard))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(refreshEpisodes))
        addCustomObserver(Constants.Notifications.playbackFailed, selector: #selector(refreshEpisodes))
        addCustomObserver(Constants.Notifications.upNextEpisodeRemoved, selector: #selector(upNextChanged))
        addCustomObserver(Constants.Notifications.upNextEpisodeAdded, selector: #selector(upNextChanged))
        addCustomObserver(Constants.Notifications.upNextQueueChanged, selector: #selector(upNextChanged))
        addCustomObserver(Constants.Notifications.searchRequested, selector: #selector(searchRequested))

        // Episode grouping can change based on download and play status, so listen for both those events and refresh when they happen
        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(refreshEpisodes))
        addCustomObserver(Constants.Notifications.episodeDownloaded, selector: #selector(refreshEpisodes))
        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(refreshEpisodes))

        if featuredPodcast, !hasAppearedAlready {
            Analytics.track(.discoverFeaturedPodcastTapped, properties: ["uuid": podcastUUID])
            AnalyticsHelper.openedFeaturedPodcast()
        }

        // if it's a local podcast, refresh it when the view appears, eg: when you tab back to it
        if let podcast = podcast, podcast.isSubscribed(), hasAppearedAlready {
            refreshEpisodes()
        }

        hasAppearedAlready = true // we use this so the page doesn't double load from viewDidLoad and viewDidAppear

        Analytics.track(.podcastScreenShown, properties: ["uuid": podcastUUID])
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        removeAllCustomObservers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let window = view.window else { return }

        let multiSelectFooterOffset: CGFloat = isMultiSelectEnabled ? 80 : 0
        episodesTable.contentInset = UIEdgeInsets(top: navBarHeight(window: window), left: 0, bottom: Constants.Values.miniPlayerOffset + multiSelectFooterOffset, right: 0)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        UIStatusBarStyle.lightContent
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchController?.hideKeyboard()
    }

    @objc private func searchRequested() {
        guard podcast != nil, let searchBar = searchController?.searchTextField else { return }

        searchBar.becomeFirstResponder()
    }

    @objc private func colorsDidDownload(_ notification: Notification) {
        guard let uuidLoaded = notification.object as? String else { return }

        if let uuid = podcast?.uuid, uuid == uuidLoaded {
            if let podcast = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) {
                self.podcast = podcast
            }
            updateColors()
        }
    }

    private func updateColors() {
        episodesTable.reloadData()
        if let podcast = podcast {
            let podcastBgColor = ColorManager.backgroundColorForPodcast(podcast)
            updateNavColors(bgColor: ThemeColor.podcastUi03(podcastColor: podcastBgColor), titleColor: UIColor.white, buttonColor: ThemeColor.contrast01())

            multiSelectHeaderView.backgroundColor = ThemeColor.podcastUi05(podcastColor: podcastBgColor)
            multiSelectCancelBtn.setTitleColor(ThemeColor.contrast01(), for: .normal)
            multiSelectAllBtn.setTitleColor(ThemeColor.contrast01(), for: .normal)
        } else {
            updateNavColors(bgColor: AppTheme.defaultPodcastBackgroundColor(), titleColor: UIColor.white, buttonColor: ThemeColor.contrast01())
        }
    }

    override func handleThemeChanged() {
        updateColors()
    }

    @objc private func podcastUpdated(_ notification: Notification) {
        guard let podcastUuid = notification.object as? String, podcastUuid == podcast?.uuid else { return }

        podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true)
        if viewIfLoaded?.window != nil {
            refreshEpisodes()
        }
    }

    @objc private func folderChanged(_ notification: Notification) {
        guard let podcastUuid = podcast?.uuid else { return }

        podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true)
        if viewIfLoaded?.window != nil {
            refreshEpisodes()
        }
    }

    @objc private func refreshEpisodes() {
        guard let podcast = podcast else { return }

        if episodesTable.numberOfSections > 0 {
            episodesTable.reloadSections([0], with: .none)
        }
        loadLocalEpisodes(podcast: podcast, animated: true)
    }

    @objc private func upNextChanged() {
        episodesTable.reloadData()
    }

    @objc private func shareTapped(_ sender: UIButton) {
        guard let podcast = podcast else { return }

        let sourceRect = sender.superview!.convert(sender.frame, to: view)
        SharingHelper.shared.shareLinkTo(podcast: podcast, fromController: self, sourceRect: sourceRect, sourceView: view)
        Analytics.track(.podcastScreenShareTapped)
    }

    private func loadPodcastInfo() {
        if let podcast = podcast {
            if podcast.isSubscribed() {
                loadLocalEpisodes(podcast: podcast, animated: false)
                checkIfPodcastNeedsUpdating()
            } else {
                let podcastUuid = podcast.uuid
                PodcastManager.shared.deletePodcastIfUnused(podcast)
                if let _ = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true) {
                    // podcast wasn't deleted, but needs to be updated
                    loadLocalEpisodes(podcast: podcast, animated: false)
                    checkIfPodcastNeedsUpdating()
                } else {
                    // podcast was deleted, reload the entire thing
                    self.podcast = nil
                    loadPodcastInfoFromUuid(podcastUuid)
                }
            }
        } else if let uuid = podcastInfo?.uuid {
            loadPodcastInfoFromUuid(uuid)
        } else if let iTunesId = podcastInfo?.iTunesId {
            loadPodcastInfoFromiTunesId(iTunesId)
        }
    }

    func loadLocalEpisodes(podcast: Podcast, animated: Bool) {
        let uuidsToFilter = (searchController?.searchInProgress() ?? false) ? uuidsThatMatchSearch : nil
        let refreshOperation = PodcastEpisodesRefreshOperation(podcast: podcast, uuidsToFilter: uuidsToFilter) { [weak self] newData in
            guard let self = self else { return }

            self.navTitle = podcast.title

            // add the episode limit placehold if it's needed
            var finalData = newData
            var needsNoEpisodesMessage = false
            var needsNoSearchResultsMessage = false
            let searching = self.searchController?.searchTextField?.text?.count ?? 0 > 0
            if podcast.podcastGrouping() == .none {
                let episodeLimit = Int(podcast.autoArchiveEpisodeLimit)
                var episodes = newData[safe: 1]?.elements
                let episodeCount = episodes?.count ?? 0
                if episodeCount > 0, episodeLimit > 0, podcast.overrideGlobalArchive {
                    var indexToInsertAt = -1
                    if PodcastEpisodeSortOrder.newestToOldest.rawValue == Int(podcast.episodeSortOrder) {
                        indexToInsertAt = episodeLimit <= episodeCount ? episodeLimit : episodeCount
                    } else if PodcastEpisodeSortOrder.oldestToNewest.rawValue == Int(podcast.episodeSortOrder) {
                        indexToInsertAt = episodeCount > episodeLimit ? episodeCount - episodeLimit : episodeCount - 1
                    }

                    if indexToInsertAt >= 0 {
                        let message = episodeLimit == 1 ? L10n.podcastLimitSingular : L10n.podcastLimitPluralFormat(episodeLimit.localized())
                        let placeholder = EpisodeLimitPlaceholder(limit: episodeLimit, message: message)
                        episodes?.insert(placeholder, at: indexToInsertAt)
                        finalData[1] = ArraySection(model: "episodes", elements: episodes!)
                    }
                } else if episodeCount == 0, searching {
                    needsNoSearchResultsMessage = true
                } else if episodeCount == 0, !self.showingArchived() {
                    needsNoEpisodesMessage = true
                }
            } else {
                var totalEpisodeCount = -1 // the search header counts as an item below, so start from -1
                for group in finalData {
                    totalEpisodeCount += group.elements.count
                }

                needsNoEpisodesMessage = totalEpisodeCount == 0 && !self.showingArchived() && !searching
                needsNoSearchResultsMessage = totalEpisodeCount == 0 && searching
            }

            if needsNoSearchResultsMessage {
                let placeholder = NoSearchResultsPlaceholder()
                finalData[1] = ArraySection(model: "episodes", elements: [placeholder])
            } else if needsNoEpisodesMessage {
                let archivedCount = self.archivedEpisodeCount()
                let message = L10n.podcastArchivedMsg(archivedCount.localized())
                let placeholder = AllArchivedPlaceholder(archived: archivedCount, message: message)
                finalData[1] = ArraySection(model: "episodes", elements: [placeholder])
            }

            if animated {
                let oldData = self.episodeInfo
                let changeSet = StagedChangeset(source: oldData, target: finalData)
                do {
                    try SJCommonUtils.catchException {
                        self.episodesTable.reload(using: changeSet, with: .none, setData: { data in
                            self.episodeInfo = data
                        })
                    }
                } catch {
                    self.episodeInfo = finalData
                    self.episodesTable.reloadData()
                }
            } else {
                self.episodeInfo = finalData
                self.episodesTable.reloadData()
            }
            self.searchController?.episodesDidReload()
            if self.isMultiSelectEnabled {
                self.updateSelectAllBtn()
            }
        }

        operationQueue.addOperation(refreshOperation)
    }

    @objc func hideSearchKeyboard() {
        searchController?.hideKeyboard()
    }

    // MARK: - PodcastActionsDelegate

    func refreshArtwork(fromRect: CGRect, inView: UIView) {
        guard let podcast = podcast else { return }

        let optionsPicker = OptionsPicker(title: nil)
        let refreshAction = OptionAction(label: L10n.podcastRefreshArtwork, icon: nil) {
            ImageManager.sharedManager.clearCache(podcastUuid: podcast.uuid, recacheWhenDone: true)
        }
        optionsPicker.addAction(action: refreshAction)

        optionsPicker.show(statusBarStyle: preferredStatusBarStyle)
    }

    func unsubscribe() {
        var downloadedCount = 0
        for object in episodeInfo[1].elements {
            guard let listEpisode = object as? ListEpisode else { continue }

            if listEpisode.episode.episodeStatus == DownloadStatus.downloaded.rawValue {
                downloadedCount += 1
            }
        }

        let optionPicker = OptionsPicker(title: downloadedCount > 0 ? nil : L10n.areYouSure)
        let unsubscribeAction = OptionAction(label: L10n.unsubscribe, icon: nil, action: { [weak self] in
            self?.performUnsubscribe()
        })
        if downloadedCount > 0 {
            unsubscribeAction.destructive = true
            optionPicker.addDescriptiveActions(title: L10n.downloadedFilesConf(downloadedCount), message: L10n.downloadedFilesConfMessage, icon: "option-alert", actions: [unsubscribeAction])
        } else {
            optionPicker.addAction(action: unsubscribeAction)
        }
        optionPicker.show(statusBarStyle: preferredStatusBarStyle)

        Analytics.track(.podcastScreenUnsubscribeTapped)
    }

    private func performUnsubscribe() {
        guard let podcast = podcast else { return }

        PodcastManager.shared.unsubscribe(podcast: podcast)
        navigationController?.popViewController(animated: true)
        Analytics.track(.podcastUnsubscribed, properties: ["source": analyticsSource, "uuid": podcast.uuid])
    }

    func subscribe() {
        guard let podcast = podcast else { return }

        podcast.subscribed = 1
        podcast.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(podcast: podcast)
        ServerPodcastManager.shared.updateLatestEpisodeInfo(podcast: podcast, setDefaults: true)
        loadLocalEpisodes(podcast: podcast, animated: true)

        if featuredPodcast {
            Analytics.track(.discoverFeaturedPodcastSubscribed, properties: ["podcast_uuid": podcast.uuid])
            AnalyticsHelper.subscribedToFeaturedPodcast()
        }
        if let listId = listUuid {
            AnalyticsHelper.podcastSubscribedFromList(listId: listId, podcastUuid: podcast.uuid)
        }

        HapticsHelper.triggerSubscribedHaptic()

        Analytics.track(.podcastScreenSubscribeTapped)
        Analytics.track(.podcastSubscribed, properties: ["source": analyticsSource, "uuid": podcast.uuid])
    }

    func isSummaryExpanded() -> Bool {
        summaryExpanded
    }

    func setSummaryExpanded(expanded: Bool) {
        summaryExpanded = expanded
    }

    func isDescriptionExpanded() -> Bool {
        descriptionExpanded
    }

    func setDescriptionExpanded(expanded: Bool) {
        descriptionExpanded = expanded
    }

    func tableView() -> UITableView {
        episodesTable
    }

    func displayedPodcast() -> Podcast? {
        podcast
    }

    func episodeCount() -> Int {
        guard let podcast = podcast else { return 0 }

        return DataManager.sharedManager.count(query: "SELECT COUNT(*) FROM \(DataManager.episodeTableName) WHERE podcast_id == ?", values: [podcast.id])
    }

    func archivedEpisodeCount() -> Int {
        guard let podcast = podcast else { return 0 }

        return DataManager.sharedManager.count(query: "SELECT COUNT(*) FROM \(DataManager.episodeTableName) WHERE podcast_id == ? AND archived = 1", values: [podcast.id])
    }

    func settingsTapped() {
        guard let podcast = podcast else { return }

        let settingsController = PodcastSettingsViewController(podcast: podcast)
        settingsController.episodes = episodeInfo
        navigationController?.pushViewController(settingsController, animated: true)
        Analytics.track(.podcastScreenSettingsTapped)
    }

    func manageSubscriptionTapped() {
        guard SyncManager.isUserLoggedIn() else {
            let signinPage = SyncSigninViewController()
            signinPage.delegate = self

            navigationController?.pushViewController(signinPage, animated: true)
            return
        }
        guard let podcast = podcast, let bundle = SubscriptionHelper.bundleSubscriptionForPodcast(podcastUuid: podcast.uuid) else { return }
        let subscriptionController = SupporterPodcastViewController(bundleSubscription: bundle)
        navigationController?.pushViewController(subscriptionController, animated: true)
    }

    func didActivateSearch() {
        // Add padding to the bottom of the table to allow it to scroll up
        let tableBounds = tableView().bounds
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: tableBounds.width, height: tableBounds.height - 320)
        view.backgroundColor = UIColor.clear
        tableView().tableFooterView = view

        // scroll the search box to the top of the page
        tableView().scrollToRow(at: IndexPath(row: NSNotFound, section: PodcastViewController.allEpisodesSection), at: .top, animated: true)
    }

    func folderTapped() {
        Analytics.track(.podcastScreenFolderTapped)
        if !SubscriptionHelper.hasActiveSubscription() {
            NavigationManager.sharedManager.showUpsellView(from: self, source: .folders)
            return
        }

        guard let podcast = podcast else { return }

        if let currentFolder = podcast.folderUuid, !currentFolder.isEmpty {
            // podcast is already in a folder, present the options for removing/moving it
            showPodcastFolderMoveOptions(currentFolderUuid: currentFolder)

            return
        }

        showFolderPickerDialog()
    }

    func searchEpisodes(query: String) {
        performEpisodeSearch(query: query)
        if !isSearching {
            isSearching = true
            Analytics.track(.podcastScreenSearchPerformed)
        }
    }

    func clearSearch() {
        guard let podcast = podcast else { return }

        uuidsThatMatchSearch.removeAll()
        loadLocalEpisodes(podcast: podcast, animated: true)
        isSearching = false
        Analytics.track(.podcastScreenSearchCleared)
    }

    func toggleShowArchived() {
        guard let podcast = podcast else { return }

        podcast.showArchived = !podcast.showArchived
        DataManager.sharedManager.save(podcast: podcast)
        loadLocalEpisodes(podcast: podcast, animated: true)

        Analytics.track(.podcastScreenToggleArchived, properties: ["show_archived": podcast.showArchived])
    }

    func showingArchived() -> Bool {
        podcast?.showArchived ?? false
    }

    func archiveAllTapped(playedOnly: Bool) {
        archiveAll(playedOnly: playedOnly)
    }

    func unarchiveAllTapped() {
        guard let podcast = podcast else { return }

        DispatchQueue.global().async {
            DataManager.sharedManager.markAllUnarchivedForPodcast(id: podcast.id)

            AnalyticsEpisodeHelper.shared.currentSource = .podcastScreen
            AnalyticsEpisodeHelper.shared.bulkUnarchiveEpisodes(count: self.episodeCount())

            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.loadLocalEpisodes(podcast: podcast, animated: false)
            }
        }
    }

    func archiveAll(playedOnly: Bool = false) {
        guard let podcast = podcast else { return }

        DispatchQueue.global().async { [weak self] in
            guard let allObjects = self?.episodeInfo[safe: 1]?.elements, allObjects.count > 0 else { return }

            var count = 0
            for object in allObjects {
                guard let listEpisode = object as? ListEpisode else { continue }
                if listEpisode.episode.archived || (playedOnly && !listEpisode.episode.played()) { continue }

                EpisodeManager.archiveEpisode(episode: listEpisode.episode, fireNotification: false, userInitiated: false)
                count += 1
            }

            AnalyticsEpisodeHelper.shared.currentSource = .podcastScreen
            AnalyticsEpisodeHelper.shared.bulkArchiveEpisodes(count: count)

            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.loadLocalEpisodes(podcast: podcast, animated: false)
            }
        }
    }

    func downloadAllTapped() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self, let allObjects = self.episodeInfo[safe: 1]?.elements, allObjects.count > 0 else { return }

            let episodes = allObjects.compactMap { ($0 as? ListEpisode)?.episode }
            AnalyticsEpisodeHelper.shared.currentSource = .podcastScreen
            AnalyticsEpisodeHelper.shared.bulkDownloadEpisodes(episodes: episodes)

            self.downloadItems(allObjects: allObjects)
        }
    }

    func downloadItems(allObjects: [ListItem]) {
        var queuedEpisodes = 0
        for object in allObjects {
            guard let listEpisode = object as? ListEpisode else { continue }

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

    func queueAllTapped() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self, let allObjects = self.episodeInfo[safe: 1]?.elements, allObjects.count > 0 else { return }
            self.queueItems(allObjects: allObjects)
        }
    }

    func queueItems(allObjects: [ListItem]) {
        var queuedEpisodes = 0
        for object in allObjects {
            guard let listEpisode = object as? ListEpisode else { continue }

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

    func downloadableEpisodeCount(items: [ListItem]? = nil) -> Int {
        guard let allObjects = items == nil ? episodeInfo[safe: 1]?.elements : items, allObjects.count > 0 else { return 0 }

        var count = 0

        for object in allObjects {
            guard let listEpisode = object as? ListEpisode else { continue }

            if !listEpisode.episode.downloaded(pathFinder: DownloadManager.shared), !listEpisode.episode.downloading(), !listEpisode.episode.queued() {
                count += 1
            }
        }
        return count
    }

    func enableMultiSelect() {
        isMultiSelectEnabled = true
    }

    private func showPodcastFolderMoveOptions(currentFolderUuid: String) {
        guard let podcast = podcast, let folder = DataManager.sharedManager.findFolder(uuid: currentFolderUuid) else { return }

        let optionsPicker = OptionsPicker(title: folder.name.localizedUppercase)
        let removeAction = OptionAction(label: L10n.folderRemoveFrom.localizedCapitalized, icon: "folder-remove") {
            podcast.sortOrder = ServerPodcastManager.shared.highestSortOrderForHomeGrid() + 1
            podcast.folderUuid = nil
            podcast.syncStatus = SyncStatus.notSynced.rawValue
            DataManager.sharedManager.save(podcast: podcast)

            DataManager.sharedManager.updateFolderSyncModified(folderUuid: currentFolderUuid, syncModified: TimeFormatter.currentUTCTimeInMillis())

            NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderChanged, object: currentFolderUuid)

            Analytics.track(.folderPodcastModalOptionTapped, properties: ["option": "remove"])
        }
        optionsPicker.addAction(action: removeAction)

        let changeFolderAction = OptionAction(label: L10n.folderChange.localizedCapitalized, icon: "folder-arrow") { [weak self] in
            guard let self = self else { return }

            self.showFolderPickerDialog()

            Analytics.track(.folderPodcastModalOptionTapped, properties: ["option": "change"])
        }
        optionsPicker.addAction(action: changeFolderAction)

        let goToFolderAction = OptionAction(label: L10n.folderGoTo.localizedCapitalized, icon: "folder-goto") {
            NavigationManager.sharedManager.navigateTo(NavigationManager.folderPageKey, data: [NavigationManager.folderKey: folder])
            Analytics.track(.folderPodcastModalOptionTapped, properties: ["option": "go_to"])
        }
        optionsPicker.addAction(action: goToFolderAction)

        optionsPicker.show(statusBarStyle: preferredStatusBarStyle)
    }

    private func showFolderPickerDialog() {
        guard let podcast = podcast else { return }

        let model = ChoosePodcastFolderModel(pickingFor: podcast.uuid, currentFolder: podcast.folderUuid)
        let chooseFolderView = ChoosePodcastFolderView(model: model) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        let hostingController = PCHostingController(rootView: chooseFolderView.environmentObject(Theme.sharedTheme))

        present(hostingController, animated: true, completion: nil)
    }

    func showBookmarks() {
        let controller = ThemedHostingController(rootView: BookmarksPodcastListView())
        present(controller, animated: true)
    }

    // MARK: - Long press actions

    func archiveAll(startingAt: Episode) {
        guard let podcast = podcast else { return }

        DispatchQueue.global().async { [weak self] in
            guard let allObjects = self?.episodeInfo[safe: 1]?.elements, allObjects.count > 0 else { return }

            var haveFoundFirst = false
            for object in allObjects {
                guard let listEpisode = object as? ListEpisode else { continue }

                if !haveFoundFirst, listEpisode.episode.uuid != startingAt.uuid { continue }

                haveFoundFirst = true
                if listEpisode.episode.archived { continue }

                EpisodeManager.archiveEpisode(episode: listEpisode.episode, fireNotification: false)
            }

            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.loadLocalEpisodes(podcast: podcast, animated: false)
            }
        }
    }

    // MARK: - Accessibility fix

    // Not quite sure why this view controller won't close with the z-gesture
    // I suspect it has something to do with the way it is pushed in MainTabController
    // Implementing the following function restores expected functionality
    override func accessibilityPerformEscape() -> Bool {
        navigationController?.popViewController(animated: true)
        return true
    }

    // MARK: - SyncSigninDelegate

    func signingProcessCompleted() {
        navigationController?.popToViewController(self, animated: true)
    }
}

// MARK: - Analytics

extension PodcastViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .podcastScreen
    }
}

private extension PodcastViewController {
    var podcastUUID: String {
        podcast?.uuid ?? podcastInfo?.analyticsDescription ?? "unknown"
    }
}
