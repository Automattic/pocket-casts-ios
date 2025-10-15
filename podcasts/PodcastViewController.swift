import Combine
import DifferenceKit
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit
import UIDeviceIdentifier
import SwiftUI
import SafariServices

enum PodcastFeedReloadSource {
    case menu
    case refreshControl

    var analyticsValue: String {
        switch self {
        case .menu:
            return "refresh_button"
        case .refreshControl:
            return "pull_to_refresh"
        }
    }
}

protocol PodcastActionsDelegate: AnyObject {
    var hasSimilarShowsPublisher: AnyPublisher<Bool, Never> { get }
    var currentViewModePublisher: AnyPublisher<PodcastViewController.ViewMode, Never> { get }
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
    func fundingTapped()
    func folderTapped()
    func notificationTapped()
    func categoryTapped(_ category: String)
    func subscribe()
    func unsubscribe()
    func refreshArtwork()
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
    var ratingView: UIView { get }

    func showBookmarks()
    func showEpisodes()
    func showYouMightLike()
    func showLogin(message: String?)

    func shouldDisplayPodcastFeedReloadButton() -> Bool
    func reloadPodcastFeed(source: PodcastFeedReloadSource)

    func open(url: URL)
}

class PodcastViewController: FakeNavViewController, PodcastActionsDelegate, SyncSigninDelegate, MultiSelectActionDelegate {
    var podcast: Podcast?
    var episodeInfo = [ArraySection<String, ListItem>]()
    var uuidsThatMatchSearch = [String]()
    var featuredPodcast = false
    var listUuid: String?
    var summaryExpanded = false
    var descriptionExpanded = false
    var currentViewMode: ViewMode = .episodes
    var hasSimilarShows = CurrentValueSubject<Bool, Never>(false)
    var isLoadingRecommendations = CurrentValueSubject<Bool, Never>(false)
    var currentViewModeSubject = CurrentValueSubject<ViewMode, Never>(.episodes)

    var hasSimilarShowsPublisher: AnyPublisher<Bool, Never> {
        hasSimilarShows.eraseToAnyPublisher()
    }

    var currentViewModePublisher: AnyPublisher<ViewMode, Never> {
        currentViewModeSubject.eraseToAnyPublisher()
    }

    var recommendations: PodcastCollection?
    var bookmarkViewModel: BookmarkPodcastListViewModel?

    enum ViewMode {
        case episodes
        case bookmarks
        case youMightLike

        var analyticsValue: String {
            switch self {
            case .episodes: return "episodes"
            case .bookmarks: return "bookmarks"
            case .youMightLike: return "you_might_like"
            }
        }
    }

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

    @IBOutlet var episodesTable: ThemeableTable! {
        didSet {
            registerCells()
            registerLongPress()
            episodesTable.rowHeight = UITableView.automaticDimension
            episodesTable.estimatedRowHeight = 80.0
            episodesTable.allowsMultipleSelectionDuringEditing = true
            episodesTable.sectionHeaderTopPadding = 0
            episodesTable.separatorStyle = .none
        }
    }

    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var loadingBgView: UIView! {
        didSet {
            loadingBgView.backgroundColor = .clear
        }
    }

    @IBOutlet var loadingImageBg: UIView! {
        didSet {
            loadingImageBg.backgroundColor = .clear
        }
    }

    @MainActor
    var isMultiSelectEnabled = false {
        didSet {
            // For non-episode cells we don't enable editing. It needs to be for Bookmarks and already if for You Might Like.
            if currentViewMode == .episodes {
                self.episodesTable.beginUpdates()
                self.episodesTable.setEditing(self.isMultiSelectEnabled, animated: true)
                if self.episodesTable.numberOfSections > 0 {
                    self.episodesTable.reloadSections(IndexSet(integersIn: 0..<self.episodesTable.numberOfSections), with: .none)
                }
                self.episodesTable.endUpdates()
            }

            if self.isMultiSelectEnabled {
                if self.selectedEpisodes.count == 0, self.longPressMultiSelectIndexPath == nil, !self.multiSelectGestureInProgress {
                    self.tableView().scrollToRow(at: IndexPath(row: NSNotFound, section: PodcastViewController.allEpisodesSection), at: .top, animated: true)
                }
                self.multiSelectFooter.setSelectedCount(count: self.selectedEpisodes.count)
                if let selectedIndexPath = self.longPressMultiSelectIndexPath {
                    self.tableView().selectIndexPath(selectedIndexPath)
                    self.longPressMultiSelectIndexPath = nil
                }
                self.multiSelectHeaderView.backgroundColor = ThemeColor.primaryUi01()
                self.multiSelectCancelBtn.setTitleColor(ThemeColor.primaryIcon01(), for: .normal)
                self.multiSelectAllBtn.setTitleColor(ThemeColor.primaryIcon01(), for: .normal)
                self.updateSelectAllBtn()
                self.multiSelectFooterBottomConstraint.constant = PlaybackManager.shared.currentEpisode() == nil ? 16 : Constants.Values.miniPlayerOffset + 16
                self.multiSelectHeaderView.isHidden = false
                self.view.bringSubviewToFront(self.multiSelectHeaderView)

                // Adjusts multiSelectHeaderView based on screen width
                self.setMultiSelectHeaderViewConstraint()
            } else {
                self.multiSelectHeaderView.isHidden = true
                self.selectedEpisodes.removeAll()
            }
            searchController?.isOverflowButtonEnabled = !self.isMultiSelectEnabled
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
        let heightConstant: CGFloat = 40
        self.multiSelectHeaderViewConstraint.constant = heightConstant + view.safeAreaInsets.top
    }

    static let headerSection = 0
    static let allEpisodesSection = 1
    static let podrollSection = 1
    static let similarShowsSection = 2

    private var isSearching = false
    private var cancellables = Set<AnyCancellable>()
    private var podcastFeedViewModel: PodcastFeedViewModel?
    private var refreshControl: CustomRefreshControl?
    private var podcastFeedReloadTooltip: UIViewController?

    // Hosting for the SwiftUI action bar used by the Bookmarks list when embedded
    private var bookmarksActionBarHost: UIHostingController<AnyView>?
    private var bookmarksActionBarBottomConstraint: NSLayoutConstraint?

    lazy var ratingView: UIView = {
        let view = StarRatingView(viewModel: podcastRatingViewModel,
                                  onRate: { [weak self] in
            self?.podcastRatingViewModel.update(podcast: self?.podcast, ignoringCache: true)
        })
            .padding(.top, 10)
            .themedUIView
        view.backgroundColor = .clear
        return view
    }()

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        setMultiSelectHeaderViewConstraint()
    }

    init(podcast: Podcast) {
        self.podcast = podcast

        // show the expanded view for unsubscribed podcasts, as well as paid podcasts that have expired and you no longer have access to play/download
        summaryExpanded = !podcast.isSubscribed()

        AnalyticsHelper.podcastOpened(uuid: podcast.uuid)
        podcastRatingViewModel.update(podcast: podcast)

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
            podcastRatingViewModel.update(podcast: podcast)
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

        if FeatureFlag.podcastFeedUpdate.enabled {
            podcastFeedViewModel = PodcastFeedViewModel(uuid: podcast?.uuid ?? podcastInfo?.uuid)

            // Let's collapse the header if the tooltip has never been showed before
            forceCollapsingHeaderIfNeeded()
        }

        closeTapped = { [weak self] in
            _ = self?.navigationController?.popViewController(animated: true)
        }

        searchController = EpisodeListSearchController()
        searchController?.podcastDelegate = self

        operationQueue.maxConcurrentOperationCount = 1

        scrollPointToChangeTitle = PodcastHeaderView.Constants.smallImageSize
        episodesTable.themeStyle = .primaryUi02
        episodesTable.addSubview(blurHeaderView)
        let blurHeaderPositionConstraint = blurHeaderView.bottomAnchor.constraint(equalTo: episodesTable.topAnchor, constant: blurHeaderPosition)
        NSLayoutConstraint.activate([
            blurHeaderPositionConstraint,
            blurHeaderView.heightAnchor.constraint(equalTo: view.widthAnchor, constant: 40),
            blurHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -20),
            blurHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20),
        ])
        self.blurHeaderPositionConstraint = blurHeaderPositionConstraint

        addRightAction(image: UIImage(named: "podcast-share"), accessibilityLabel: L10n.share, action: #selector(shareTapped(_:)))
        addGoogleCastBtn()
        loadPodcastInfo()

        NotificationCenter.default.addObserver(self, selector: #selector(podcastUpdated(_:)), name: Constants.Notifications.podcastUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(folderChanged(_:)), name: Constants.Notifications.folderChanged, object: nil)

        listenForBookmarkChanges()
        setupLogin()
        setupBookmarkViewModel()

        setupRefreshControl()

        // Keep external action bar aligned with mini player
        NotificationCenter.default.addObserver(self, selector: #selector(miniPlayerStatusDidChange), name: Constants.Notifications.miniPlayerDidAppear, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(miniPlayerStatusDidChange), name: Constants.Notifications.miniPlayerDidDisappear, object: nil)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)

        if scrollView.isDragging || scrollView.isDecelerating {
            dismissKeyboardForScrollIfNeeded()
        }
        if FeatureFlag.podcastFeedUpdate.enabled {
            refreshControl?.scrollViewDidScroll(scrollView)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if FeatureFlag.podcastFeedUpdate.enabled {
            refreshControl?.scrollViewDidEndDragging(scrollView)
        }
    }

    private func setupLogin() {
        podcastRatingViewModel.presentLogin = { [weak self] viewModel in
            self?.showLogin(message: L10n.ratingLoginRequired)
        }
    }

    private func setupBookmarkViewModel() {
        guard let podcast = podcast else { return }

        let sortOption = Settings.podcastBookmarksSort
        let viewModel = BookmarkPodcastListViewModel(podcast: podcast,
                                                      bookmarkManager: PlaybackManager.shared.bookmarkManager,
                                                      sortOption: sortOption)
        viewModel.analyticsSource = .podcasts
        viewModel.router = self

        self.bookmarkViewModel = viewModel
    }

    func showLogin(message: String?) {
        let loginViewController = LoginCoordinator.make()
        present(loginViewController, animated: true)
        if let message {
            Toast.show(message)
        }
    }

    private func listenForBookmarkChanges() {
        let bookmarkManager = PlaybackManager.shared.bookmarkManager

        // Refresh when a bookmark is added to our podcast
        bookmarkManager.onBookmarkCreated
            .filter({ [weak self] event in
                event.podcast == self?.podcast?.uuid
            })
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.upNextChanged()
            })
            .store(in: &cancellables)

        // Reload when a bookmark is deleted
        bookmarkManager.onBookmarksDeleted
            .filter({ [weak self] event in
                event.items.contains(where: { $0.podcast == self?.podcast?.uuid })
            })
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.upNextChanged()
            })
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Load the ratings even if we've already started loading them to cover all other potential view states
        // The view model will ignore extra calls
        if let _ = [podcast?.uuid, podcastInfo?.uuid].compactMap({ $0 }).first {
            podcastRatingViewModel.update(podcast: podcast)
        }
        self.navigationController?.isNavigationBarHidden = true
        updateColors()
    }

    lazy var blurHeaderView: UIView = {
        let headerView = PodcastBlurHeaderView(podcastUUID: self.podcastUUID).uiView
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .clear
        headerView.layer.zPosition = -1000
        headerView.isUserInteractionEnabled = false
        return headerView
    }()

    var blurHeaderPositionConstraint: NSLayoutConstraint?

    private var blurHeaderPosition: CGFloat {
        summaryExpanded ? PodcastHeaderView.Constants.largeImageSize : PodcastHeaderView.Constants.smallImageSize / 2
    }

    lazy var podcastHeaderCell: PodcastHeaderCell = {
        return PodcastHeaderCell(podcast: self.podcast!, vc: self)
    }()

    private var hasAppearedAlready = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        addCustomObserver(Constants.Notifications.podcastColorsDownloaded, selector: #selector(colorsDidDownload(_:)))
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

        var properties = ["uuid": podcastUUID]
        if let listUuid {
            properties["list_id"] = listUuid
        }
        Analytics.track(.podcastScreenShown, properties: properties)

        if FeatureFlag.podcastFeedUpdate.enabled {
            refreshControl?.parentViewControllerDidAppear()
            showPodcastFeedReloadTipIfNeeded()
        }
        self.navigationController?.isNavigationBarHidden = true
        showViewChangesTipIfNeeded()

        // Load recommendations when view appears
        if FeatureFlag.recommendations.enabled && recommendations == nil {
            Task {
                await loadRecommendations()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if FeatureFlag.podcastFeedUpdate.enabled {
            podcastFeedViewModel?.cancelTask()
            Toast.dismiss()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        removeAllCustomObservers()

        if FeatureFlag.podcastFeedUpdate.enabled {
            refreshControl?.parentViewControllerDidDisappear()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let window = view.window else { return }

        let multiSelectFooterOffset: CGFloat = isMultiSelectEnabled ? 80 : 0
        let miniPlayerOffset: CGFloat = PlaybackManager.shared.currentEpisode() == nil ? 0 : Constants.Values.miniPlayerOffset
        episodesTable.contentInset = UIEdgeInsets(top: navBarHeight(window: window), left: 0, bottom: miniPlayerOffset + multiSelectFooterOffset, right: 0)
        episodesTable.verticalScrollIndicatorInsets = episodesTable.contentInset
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dismissKeyboardForScrollIfNeeded()
    }

    private func dismissKeyboardForScrollIfNeeded() {
        searchController?.hideKeyboard()
        view.endEditing(true)
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

    func reloadData() {
        episodesTable.reloadData()
    }

    private func updateColors() {
        reloadData()
        if let podcast = podcast {
            updateNavColors(bgColor: .clear, titleColor: ThemeColor.primaryText01(), buttonColor: UIColor.white, buttonBackgroundColor: UIColor.black.withAlphaComponent(0.32))

            multiSelectHeaderView.backgroundColor = ThemeColor.primaryUi01()
            multiSelectCancelBtn.setTitleColor(ThemeColor.primaryIcon01(), for: .normal)
            multiSelectAllBtn.setTitleColor(ThemeColor.primaryIcon01(), for: .normal)
            // we need to do this for scenarios when theme was changed
            updateNavigationBar(position: episodesTable.contentOffset.y)
        } else {
            updateNavColors(bgColor: .clear, titleColor: ThemeColor.primaryText01(), buttonColor: UIColor.white, buttonBackgroundColor: UIColor.black.withAlphaComponent(0.32))
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

        loadLocalEpisodes(podcast: podcast, animated: true)
    }

    @objc private func upNextChanged() {
        reloadData()
    }

    @objc private func shareTapped(_ sender: UIButton) {
        guard let podcast = podcast else { return }

        let sourceRect = sender.superview!.convert(sender.frame, to: view)
        SharingHelper.shared.shareLinkTo(podcast: podcast, fromController: self, fromSource: analyticsSource, sourceRect: sourceRect, sourceView: view)
        Analytics.track(.podcastScreenShareTapped, properties: ["podcast_uuid": podcast.uuid, "is_private": podcast.isPrivate])
    }

    private func loadPodcastInfo() {
        if let podcast = podcast {
            if podcast.isSubscribed() {
                loadLocalEpisodes(podcast: podcast, animated: false)
                checkIfPodcastNeedsUpdating()
            } else {
                let podcastUuid = podcast.uuid
                Task {
                    await PodcastManager.shared.deletePodcastIfUnused(podcast)
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
                let episodeLimit = Int(podcast.autoArchiveEpisodeLimitCount)
                var episodes = newData[safe: 1]?.elements
                let episodeCount = episodes?.count ?? 0
                if episodeCount > 0, episodeLimit > 0, podcast.isAutoArchiveOverridden {
                    var indexToInsertAt = -1

                    let episodeSortOrder = podcast.podcastSortOrder

                    switch episodeSortOrder {
                    case .newestToOldest:
                        indexToInsertAt = episodeLimit <= episodeCount ? episodeLimit : episodeCount
                    case .oldestToNewest:
                        indexToInsertAt = episodeCount > episodeLimit ? episodeCount - episodeLimit : episodeCount - 1
                    default:
                        ()
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
                    reloadData()
                }
            } else {
                self.episodeInfo = finalData
                reloadData()
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

    func refreshArtwork() {
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
        let label = FeatureFlag.useFollowNaming.enabled ? L10n.unfollow : L10n.unsubscribe
        let unsubscribeAction = OptionAction(label: label, icon: nil, action: { [weak self] in
            self?.performUnsubscribe()
        })
        if downloadedCount > 0 {
            unsubscribeAction.destructive = true
            let message = FeatureFlag.useFollowNaming.enabled ? L10n.downloadedFilesConfMessageNew : L10n.downloadedFilesConfMessage
            optionPicker.addDescriptiveActions(title: L10n.downloadedFilesConf(downloadedCount), message: message, icon: "option-alert", actions: [unsubscribeAction])
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
        podcast.autoDownloadSetting = (FeatureFlag.autoDownloadOnSubscribe.enabled && Settings.autoDownloadEnabled() && Settings.autoDownloadOnFollow() ? AutoDownloadSetting.latest : AutoDownloadSetting.off).rawValue
        DataManager.sharedManager.save(podcast: podcast)
        ServerPodcastManager.shared.updateLatestEpisodeInfo(podcast: podcast, setDefaults: true, autoDownloadLimit: Settings.autoDownloadOnFollow() ? Settings.autoDownloadLimits().rawValue : 0)
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
        blurHeaderPositionConstraint?.constant = blurHeaderPosition
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    func isDescriptionExpanded() -> Bool {
        descriptionExpanded
    }

    func setDescriptionExpanded(expanded: Bool) {
        descriptionExpanded = expanded
    }

    @objc private func miniPlayerStatusDidChange() {
        updateBookmarksActionBarBottomConstraint()
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

    func fundingTapped() {
        Analytics.track(.podcastScreenFundingTapped, properties: ["podcast_uuid": podcast?.uuid ?? ""])
        guard let urlString = podcast?.fundingURL, let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
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

    func notificationTapped() {
        guard let podcast else {
            return
        }
        let newValue = !podcast.isPushEnabled
        Analytics.track(.podcastScreenNotificationsTapped, properties: ["enabled": newValue])
        NotificationsHelper.shared.registerForPushNotifications() { granted in
            guard granted || !newValue else {
                Toast.show(L10n.notificationsPermissionsNeedsAction, actions: [.init(title: L10n.notificationsPermissionsOpenSettings, action: {
                    Analytics.track(.notificationsPermissionsOpenSystemSettings)
                    UIApplication.shared.openNotificationSettings()
                })])
                return
            }
            PodcastManager.shared.setNotificationsEnabled(podcast: podcast, enabled: newValue)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast.uuid)
            var message = newValue ? L10n.notificationsOn : L10n.notificationsOff
            if let title = podcast.title, newValue {
                message = L10n.notificationsOnForPodcast(title)
            }
            Toast.show(message)
        }
    }

    func categoryTapped(_ category: String) {
        NavigationManager.sharedManager.navigateTo(NavigationManager.discoverPageKey, data: [NavigationManager.discoverCategoryKey: category])
        Analytics.track(.podcastScreenCategoryTapped, properties: ["category": category])
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

        podcast.shouldShowArchived = !podcast.shouldShowArchived
        DataManager.sharedManager.save(podcast: podcast)
        loadLocalEpisodes(podcast: podcast, animated: true)

        Analytics.track(.podcastScreenToggleArchived, properties: ["show_archived": podcast.shouldShowArchived])
    }

    func showingArchived() -> Bool {
        podcast?.shouldShowArchived ?? false
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

    func showOptionsFor(season: Int) {
        guard let podcast else {
            return
        }

        Analytics.track(.podcastScreenSeasonOptionsTapped, properties: ["season": season])

        let optionPicker = OptionsPicker(title: nil)

        optionPicker.addActions([
            .init(label: L10n.selectAll, icon: "option-multiselect") { [weak self] in
                self?.selectSeasonTapped(season: season)
                Analytics.track(.podcastScreenSeasonOptionsSelectAllTapped, properties: ["season": season])
            },
            downloadActionForSeason(season),
            archiveActionForSeason(season)
        ].compactMap(\.self))

        optionPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }

    private func downloadActionForSeason(_ season: Int) -> OptionAction? {
        var allDownloaded = true
        let episodes = episodesForSeason(season).map({ $0.episode })
        for episode in episodes {
            if !episode.downloaded(pathFinder: DownloadManager.shared) {
                allDownloaded = false
                break
            }
        }
        if allDownloaded {
            return .init(label: L10n.removeAll, icon: "episode-remove-download") {
                EpisodeManager.removeDownloadForEpisodes(episodes)
                Analytics.track(.podcastScreenSeasonOptionsRemoveAllTapped, properties: ["season": season])
            }
        } else {
            return .init(label: L10n.downloadAll, icon: "player-download") { [weak self] in
                self?.downloadSeasonTapped(season: season)
                Analytics.track(.podcastScreenSeasonOptionsDownloadAllTapped, properties: ["season": season])
            }
        }
    }

    private func archiveActionForSeason(_ season: Int) -> OptionAction? {
        guard let podcast else { return nil }
        let unarchivedQuery = "SELECT COUNT(*) FROM \(DataManager.episodeTableName) WHERE podcast_id = ? AND archived = 0 AND seasonNumber = ?"
        let unarchivedCount = DataManager.sharedManager.count(query: unarchivedQuery, values: [podcast.id, season])
        if unarchivedCount > 0 {
            return OptionAction(label: L10n.podcastArchiveAll, icon: "options-archiveall") { [weak self] in
                self?.archiveAllSeasonTapped(season: season)
                Analytics.track(.podcastScreenSeasonOptionsArchiveAllTapped, properties: ["season": season])
            }
        } else {
            return OptionAction(label: L10n.podcastUnarchiveAll, icon: "list_unarchive") { [weak self] in
                self?.unarchiveAllSeasonTapped(season: season)
                Analytics.track(.podcastScreenSeasonOptionsUnarchiveAllTapped, properties: ["season": season])
            }
        }
    }

    private func episodesForSeason(_ season: Int) -> [ListEpisode] {
        guard let allObjects = self.episodeInfo[safe: 1]?.elements,
              allObjects.count > 0
        else {
            return []
        }

        let seasonObjects = allObjects.filter {
            guard let listEpisode = $0 as? ListEpisode else {
                return false
            }
            return listEpisode.episode.seasonNumber == season
        }

        let episodes = seasonObjects.compactMap { ($0 as? ListEpisode) }.filter { $0.episode.seasonNumber == season }
        return episodes
    }

    private func selectSeasonTapped(season: Int) {
        selectedEpisodes = episodesForSeason(season)
        enableMultiSelect()
        DispatchQueue.main.async { [weak self] in
            self?.reloadData()
        }
    }

    func downloadSeasonTapped(season: Int) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            let listEpisodesForSeason = episodesForSeason(season)
            let episodes = listEpisodesForSeason.map { $0.episode }

            AnalyticsEpisodeHelper.shared.currentSource = .podcastScreen
            AnalyticsEpisodeHelper.shared.bulkDownloadEpisodes(episodes: episodes)

            self.downloadItems(allObjects: listEpisodesForSeason)
        }
    }

    func archiveAllSeasonTapped(season: Int) {
        let listEpisodesForSeason = episodesForSeason(season)
        let episodes = listEpisodesForSeason.map { $0.episode }
        EpisodeManager.bulkArchive(episodes: episodes, updateSyncFlag: true)
    }

    func unarchiveAllSeasonTapped(season: Int) {
        let listEpisodesForSeason = episodesForSeason(season)
        let episodes = listEpisodesForSeason.map { $0.episode }
        EpisodeManager.bulkUnarchive(episodes: episodes)
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

    // MARK: - External Bookmarks Action Bar

    func updateBookmarksActionBar(state: ExternalActionBarState, viewModel: BookmarkPodcastListViewModel) {
        if state.isMultiSelecting {
            // Ensure top nav/selection header matches multiselect state
            if !isMultiSelectEnabled {
                isMultiSelectEnabled = true
            }
            // Hide the table's native multiSelectFooter; we present a SwiftUI bar instead
            multiSelectFooter.isHidden = true

            let actions: [ActionBarView<ThemedActionBarStyle>.Action] = makeBookmarkActions(BookmarkActionConfig(
                showShare: state.showShare,
                showEdit: state.showEdit,
                onShare: { viewModel.shareSelectedBookmarks() },
                onEdit: { viewModel.editSelectedBookmarks() },
                onDelete: { viewModel.deleteSelectedBookmarks() }
            ))

            let bar = ActionBarView(title: state.title, style: ThemedActionBarStyle(), actions: actions)
                .padding(.bottom) // match internal spacing

            if let host = bookmarksActionBarHost {
                host.rootView = AnyView(bar)
            } else {
                let host = UIHostingController(rootView: AnyView(bar))
                host.view.backgroundColor = .clear
                bookmarksActionBarHost = host

                addChild(host)
                view.addSubview(host.view)
                host.view.translatesAutoresizingMaskIntoConstraints = false

                let bottom = host.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
                bookmarksActionBarBottomConstraint = bottom

                NSLayoutConstraint.activate([
                    host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    bottom
                ])

                host.didMove(toParent: self)

                // Ensure initial layout has the correct offset without animating from the top
                updateBookmarksActionBarBottomConstraint(animated: false)
            }

            if state.visible {
                // Subsequent updates can animate
                updateBookmarksActionBarBottomConstraint(animated: true)
            } else {
                // If not visible (no selected items), remove bar if present
                removeBookmarksActionBar()
            }
            // Keep Select All button title in sync
            updateSelectAllBtn()
        } else {
            removeBookmarksActionBar()
            if isMultiSelectEnabled {
                isMultiSelectEnabled = false
            }
        }
    }

    private func updateBookmarksActionBarBottomConstraint(animated: Bool = true) {
        guard let bottom = bookmarksActionBarBottomConstraint else { return }
        guard let host = bookmarksActionBarHost else { return }
        bottom.constant = -bookmarksActionBarBottomOffset()
        if animated {
            UIView.animate(withDuration: 0.1) { host.view.layoutIfNeeded(); self.view.layoutIfNeeded() }
        } else {
            host.view.layoutIfNeeded()
            self.view.layoutIfNeeded()
        }
    }

    func removeBookmarksActionBar() {
        if let host = bookmarksActionBarHost {
            host.willMove(toParent: nil)
            host.view.removeFromSuperview()
            host.removeFromParent()
        }
        bookmarksActionBarHost = nil
        bookmarksActionBarBottomConstraint = nil
    }

    private func bookmarksActionBarBottomOffset() -> CGFloat {
        let miniPlayerOffset = PlaybackManager.shared.currentEpisode() == nil ? 0 : Constants.Values.miniPlayerOffset
        return miniPlayerOffset
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

    func showEpisodes() {
        switchViewMode(to: .episodes)
    }

    func showBookmarks() {
        if FeatureFlag.podcastBookmarksInline.enabled {
            switchViewMode(to: .bookmarks)
        } else {
            guard let podcast else { return }
            let controller = BookmarksPodcastListController(podcast: podcast)
            present(controller, animated: true)
        }
    }

    func showYouMightLike() {
        switchViewMode(to: .youMightLike)
    }

    // MARK: - Podcast Feed Reload

    private func setupRefreshControl() {
        if shouldDisplayPodcastFeedReloadButton() {
            refreshControl = CustomRefreshControl()
            refreshControl?.customTintColor = contrastColorForPodcastImage
            refreshControl?.perform = { [weak self] in
                self?.reloadPodcastFeed(source: .refreshControl)
            }
            episodesTable.refreshControl = refreshControl
        }
    }

    private var contrastColorForPodcastImage: UIColor {
        guard let image = ImageManager.sharedManager.cachedImageFor(podcastUuid: self.podcastUUID, size: .grid) else {
            return .white
        }
        return image.isDark ? .white : .black
    }

    func shouldDisplayPodcastFeedReloadButton() -> Bool {
        return FeatureFlag.podcastFeedUpdate.enabled && podcastFeedViewModel?.uuid != nil
    }

    func reloadPodcastFeed(source: PodcastFeedReloadSource) {
        // In case the FF is switched off
        guard shouldDisplayPodcastFeedReloadButton() else {
            refreshControl?.endRefreshing()
            return
        }
        if podcastFeedViewModel?.loadingState == .loading {
            return
        }

        //TODO: Add analytics based on source

        Task { @MainActor [weak self] in
            let podcastNeedsReload = await self?.podcastFeedViewModel?.checkIfNewEpisodesAreAvailable(from: source) ?? false
            if podcastNeedsReload {
                self?.loadPodcastInfo()
            }
        }
    }

    func refreshPodcastFeed() {
        // In case the FF is switched off
        guard shouldDisplayPodcastFeedReloadButton() else {
            refreshControl?.endRefreshing()
            return
        }
        reloadPodcastFeed(source: .refreshControl)
    }

    func open(url: URL) {
        if Settings.openLinks {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            if URLHelper.isValidScheme(url.scheme) {
                let safariViewController = SFSafariViewController(with: url)
                safariViewController.delegate = self

                NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
                SceneHelper.rootViewController()?.present(safariViewController, animated: true, completion: nil)
            } else if URLHelper.isMailtoScheme(url.scheme), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    private func dismissPodcastFeedReloadTip() {
        guard Settings.shouldShowPodcastFeeReloadTip,
            let podcastFeedReloadTooltip
        else {
            return
        }
        Analytics.track(.podcastRefreshEpisodeTooltipDismissed)
        Settings.shouldShowPodcastFeeReloadTip = false
        podcastFeedReloadTooltip.dismiss(animated: true) { [weak self] in
            self?.podcastFeedReloadTooltip = nil
        }
    }

    func forceCollapsingHeaderIfNeeded() {
        if FeatureFlag.podcastFeedUpdate.enabled {
            if Settings.shouldShowPodcastFeeReloadTip, summaryExpanded {
                summaryExpanded = false
            }
        }
    }

    func showPodcastFeedReloadTipIfNeeded() {
        guard
            Settings.shouldShowPodcastFeeReloadTip,
            FeatureFlag.podcastFeedUpdate.enabled,
            podcastFeedReloadTooltip == nil
        else {
            return
        }
        if let vc = showPodcastFeedReloadTip() {
            present(vc, animated: true) {
                Analytics.track(.podcastRefreshEpisodeTooltipShown)
            }
            podcastFeedReloadTooltip = vc
        }
    }

    private func showPodcastFeedReloadTip() -> UIViewController? {
        guard let button = searchController?.overflowButton else {
            return nil
        }
        let vc = UIHostingController(rootView: AnyView (EmptyView()) )
        let idealSize = CGSizeMake(290, 100)
        let tipView = TipViewStatic(title: L10n.podcastFeedReloadTipTitle,
                                    message: L10n.podcastFeedReloadTipMessage,
                              onTap: { [weak self] in
            self?.dismissPodcastFeedReloadTip()
        })
            .frame(idealWidth: idealSize.width, minHeight: idealSize.height)
            .setupDefaultEnvironment()
        vc.rootView = AnyView(tipView)
        vc.view.backgroundColor = .clear
        vc.view.clipsToBounds = false
        vc.modalPresentationStyle = .popover
        vc.sizingOptions = [.preferredContentSize]
        if let popoverPresentationController = vc.popoverPresentationController {
            popoverPresentationController.delegate = self
            popoverPresentationController.permittedArrowDirections = [.down]
            popoverPresentationController.sourceView = button
            popoverPresentationController.sourceRect = button.bounds
            popoverPresentationController.backgroundColor = ThemeColor.primaryUi01()
        }
        return vc
    }

    private var viewChangesTipVC: UIViewController?
    private var dimmingView: UIView?

    func showViewChangesTipIfNeeded() {
        guard Settings.shouldShowPodcastViewChangesTip,
              self.podcast != nil,
              viewChangesTipVC == nil
        else {
            return
        }
        Settings.shouldShowPodcastViewChangesTip = false
        var point = podcastHeaderCell.center
        point.y = summaryExpanded ? 1.4 * PodcastHeaderView.Constants.largeImageSize : 1.4 * PodcastHeaderView.Constants.smallImageSize
        let rect = CGRect(origin: point, size: .zero)
        viewChangesTipVC = showTip(title: L10n.podcastViewChangesTipTitle, message: L10n.podcastViewChangesTipDetails, sourceView: podcastHeaderCell, sourceRect: rect) { [weak self] in
            self?.dismissViewChangesTip()
        }
    }

    private func dismissViewChangesTip() {
        guard let viewChangesTipVC else {
            return
        }
        viewChangesTipVC.dismiss(animated: true)
        dimmingView?.removeFromSuperview()
        self.viewChangesTipVC = nil
    }

    private func showTip(title: String, message: String, sourceView: UIView, sourceRect: CGRect = CGRectNull, dimBackground: Bool = true, action: @escaping () -> ()) -> UIViewController {
        if dimBackground {
            let dimmingView = UIView(frame: self.view.bounds)
            dimmingView.backgroundColor = .black.withAlphaComponent(0.3)
            self.tabBarController?.view.addSubview(dimmingView)
            self.dimmingView = dimmingView
        }
        let vc = UIHostingController(rootView: AnyView (EmptyView()) )
        let idealSize = CGSizeMake(290, 100)
        let tipView = TipViewStatic(title: title,
                                    message: message,
                                    showClose: true,
                              onTap: {
            action()
        })
            .frame(idealWidth: idealSize.width, minHeight: idealSize.height)
            .setupDefaultEnvironment()
        vc.rootView = AnyView(tipView)
        vc.view.backgroundColor = .clear
        vc.view.clipsToBounds = false
        vc.modalPresentationStyle = .popover
        vc.sizingOptions = [.preferredContentSize]
        if let popoverPresentationController = vc.popoverPresentationController {
            popoverPresentationController.delegate = self
            popoverPresentationController.permittedArrowDirections = [.down]
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceRect
            popoverPresentationController.backgroundColor = ThemeColor.primaryUi01()
        }
        present(vc, animated: true)
        return vc
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

    @MainActor
    func loadRecommendations() async {
        guard let podcast = podcast else { return }

        isLoadingRecommendations.send(true)
        updateEmptyStateVisibility()

        do {
            var originalRecommendations = try await ServerPodcastManager.shared.loadRecommendations(for: podcast.uuid, in: Settings.userRegion())
            filterCurrentPodcast(from: &originalRecommendations)
            recommendations = originalRecommendations
            guard !Task.isCancelled else { return }
            hasSimilarShows.send(recommendations?.podcasts?.isEmpty == false)
        } catch {
            // We won't do anything in the interface here since the You Might Like button is optional and hidden by default
            FileLog.shared.addMessage("[PodcastViewController] Failed to load recommendations \(error)")
            guard !Task.isCancelled else { return }
            hasSimilarShows.send(false)
        }

        isLoadingRecommendations.send(false)
        updateEmptyStateVisibility()
    }

    private func filterCurrentPodcast(from collection: inout PodcastCollection?) {
        if var podcasts = collection?.podcasts {
            podcasts = podcasts.filter { $0.uuid != self.podcast?.uuid }
            collection?.podcasts = podcasts
        }
    }

    private func updateEmptyStateVisibility() {
        if currentViewMode == .youMightLike {
            episodesTable.reloadData()
        }
    }

    private func switchViewMode(to mode: ViewMode) {
        // Clear any externally presented action bar when switching modes
        removeBookmarksActionBar()
        if isMultiSelectEnabled {
            isMultiSelectEnabled = false
        }
        currentViewMode = mode
        currentViewModeSubject.send(mode)
        switch mode {
        case .episodes:
            if let podcast = podcast {
                loadLocalEpisodes(podcast: podcast, animated: true)
            }
        case .youMightLike:
            updateEmptyStateVisibility()
            if recommendations == nil {
                Task {
                    await loadRecommendations()
                }
            }
        case .bookmarks:
            if bookmarkViewModel == nil {
                setupBookmarkViewModel()
            }
            bookmarkViewModel?.reload()
        }
        Analytics.track(.podcastsScreenTabTapped, properties: ["value": mode.analyticsValue])
        reloadData()
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

extension PodcastViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        dismissPodcastFeedReloadTip()
        dismissViewChangesTip()
    }
}

extension PodcastViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
        controller.delegate = nil
    }
}

// MARK: - BookmarkListRouter

extension PodcastViewController: BookmarkListRouter {
    func bookmarkPlay(_ bookmark: Bookmark) {
        PlaybackManager.shared.playBookmark(bookmark, source: .podcasts)
    }

    func bookmarkEdit(_ bookmark: Bookmark) {
        let controller = BookmarkEditTitleViewController(manager: PlaybackManager.shared.bookmarkManager, bookmark: bookmark, state: .updating)
        controller.source = .podcasts

        present(controller, animated: true)
    }

    func bookmarkShare(_ bookmark: Bookmark) {
        guard let episode = bookmark.episode as? Episode else {
            return
        }
        Analytics.track(.bookmarkShareTapped, source: analyticsSource, properties: ["podcast_uuid": episode.podcastUuid, "episode_uuid": bookmark.episodeUuid])
        SharingModal.show(option: .bookmark(episode, bookmark.time), from: .podcastScreen, in: self)
    }

    func dismissBookmarksList() {
        // For tab-based bookmarks, we switch to episodes view instead of dismissing
        switchViewMode(to: .episodes)
    }
}
