import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class EpisodeListSearchController: SimpleNotificationsViewController, UISearchBarDelegate {
    weak var podcastDelegate: PodcastActionsDelegate?

    // search
    @IBOutlet var roundedBackgroundView: UIView!
    @IBOutlet var searchTextField: UITextField! {
        didSet {
            searchTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        }
    }

    @IBOutlet var searchIcon: UIImageView!
    @IBOutlet var loadingSpinner: ThemeLoadingIndicator!
    @IBOutlet var clearSearchBtn: UIButton!

    var searchTimer: Timer?
    var searching = false

    @IBOutlet var episodeInfoLabel: ThemeableLabel! {
        didSet {
            episodeInfoLabel.style = .primaryText02
        }
    }

    @IBOutlet var archivedInfoLabel: ThemeableLabel! {
        didSet {
            archivedInfoLabel.style = .primaryText02
        }
    }

    @IBOutlet var episodeInfoSeparatorLabel: ThemeableLabel! {
        didSet {
            episodeInfoSeparatorLabel.style = .primaryText02
        }
    }

    @IBOutlet var limitLabel: ThemeableLabel! {
        didSet {
            limitLabel.style = .support08
        }
    }

    @IBOutlet var showHideArchiveBtn: UIButton!
    @IBOutlet var overflowButton: ThemeSecondaryButton!
    var isOverflowButtonEnabled = true {
        didSet {
            overflowButton.isEnabled = isOverflowButtonEnabled
        }
    }

    @IBOutlet var dividerHeightConstraint: NSLayoutConstraint! {
        didSet {
            dividerHeightConstraint.constant = 1 / UIScreen.main.scale
        }
    }

    @IBOutlet var middleDividerHeightConstraint: NSLayoutConstraint! {
        didSet {
            middleDividerHeightConstraint.constant = 1 / UIScreen.main.scale
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        showHideArchiveBtn.titleLabel?.textAlignment = .center
        showHideArchiveBtn.titleLabel?.heightAnchor.constraint(equalTo: showHideArchiveBtn.heightAnchor).isActive = true
        updateInfoView()
        themeChanged()
        addCustomObserver(Constants.Notifications.themeChanged, selector: #selector(themeChanged))
    }

    deinit {
        removeAllCustomObservers()
    }

    @objc private func textFieldDidChange() {
        handleTextFieldDidChange()
    }

    @objc private func themeChanged() {
        view.backgroundColor = ThemeColor.primaryUi02()

        searchTextField.backgroundColor = UIColor.clear
        searchTextField.textColor = ThemeColor.primaryText02()
        searchTextField.attributedPlaceholder = NSAttributedString(string: L10n.search, attributes: [NSAttributedString.Key.foregroundColor: ThemeColor.primaryText02()])
        searchTextField.keyboardAppearance = AppTheme.keyboardAppearance()
        roundedBackgroundView.backgroundColor = ThemeColor.primaryField01()
        searchIcon.tintColor = ThemeColor.primaryIcon02()
        clearSearchBtn.tintColor = ThemeColor.primaryIcon02()
        showHideArchiveBtn.tintColor = ThemeColor.primaryInteractive01()
    }

    private func updateInfoView() {
        guard let delegate = podcastDelegate, let podcast = delegate.displayedPodcast() else { return }

        let episodeCount = delegate.episodeCount()
        let archivedCount = delegate.archivedEpisodeCount()
        let hasEpisodeLimit = (podcast.autoArchiveEpisodeLimit > 0 && podcast.overrideGlobalArchive)

        episodeInfoLabel?.text = episodeCount == 1 ? L10n.podcastEpisodeCountSingular : L10n.podcastEpisodeCountPluralFormat(episodeCount.localized())

        limitLabel?.text = L10n.podcastEpisodeLimitCountFormat(podcast.autoArchiveEpisodeLimit.localized())
        archivedInfoLabel?.text = L10n.podcastArchivedCountFormat(archivedCount.localized())

        limitLabel?.isHidden = !hasEpisodeLimit
        archivedInfoLabel?.isHidden = hasEpisodeLimit

        let archivedTitle = delegate.showingArchived() ? L10n.podcastHideArchived : L10n.podcastShowArchived
        if let showHideBtn = showHideArchiveBtn {
            UIView.performWithoutAnimation {
                showHideBtn.setTitle(archivedTitle, for: .normal)
                showHideBtn.layoutIfNeeded()
            }
        }
    }

    func episodesDidReload() {
        updateInfoView()
    }

    @IBAction func showHideArchiveTapped(_ sender: Any) {
        podcastDelegate?.toggleShowArchived()
    }

    @IBAction func overflowTapped(_ sender: Any) {
        guard let delegate = podcastDelegate, let podcast = delegate.displayedPodcast() else { return }

        let optionPicker = OptionsPicker(title: nil)

        let MultiSelectAction = OptionAction(label: L10n.selectEpisodes, icon: "option-multiselect") { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.podcastDelegate?.enableMultiSelect()
        }
        optionPicker.addAction(action: MultiSelectAction)

        let episodeSortOrder = podcast.podcastSortOrder

        let currentSort = episodeSortOrder?.description ?? ""
        let sortAction = OptionAction(label: L10n.sortEpisodes, secondaryLabel: currentSort, icon: "podcastlist_sort") { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.presentSortOptions()
        }
        optionPicker.addAction(action: sortAction)

        let currentGroup = PodcastGrouping(rawValue: podcast.episodeGrouping)?.description ?? ""
        let groupAction = OptionAction(label: L10n.groupEpisodes, secondaryLabel: currentGroup, icon: "option-group") { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.presentGroupOptions()
        }
        optionPicker.addAction(action: groupAction)

        let downloadAllAction = OptionAction(label: L10n.downloadAll, icon: "filter_downloaded") { [weak self] in
            let downloadableCount = delegate.downloadableEpisodeCount(items: nil)
            let downloadLimitExceeded = downloadableCount > Constants.Limits.maxBulkDownloads
            let actualDownloadCount = downloadLimitExceeded ? Constants.Limits.maxBulkDownloads : downloadableCount
            if actualDownloadCount == 0 { return }
            let downloadText = L10n.downloadCountPrompt(actualDownloadCount)
            let downloadAction = OptionAction(label: downloadText, icon: nil) { () in
                delegate.downloadAllTapped()
            }

            let confirmPicker = OptionsPicker(title: nil)
            var warningMessage = downloadLimitExceeded ? L10n.bulkDownloadMax : ""

            if NetworkUtils.shared.isConnectedToWifi() {
                confirmPicker.addDescriptiveActions(title: L10n.downloadAll, message: warningMessage, icon: "filter_downloaded", actions: [downloadAction])
            } else {
                downloadAction.destructive = true

                let queueAction = OptionAction(label: L10n.queueForLater, icon: nil) {
                    delegate.queueAllTapped()
                }

                if !Settings.mobileDataAllowed() {
                    warningMessage = L10n.downloadDataWarning + "\n" + warningMessage
                }
                confirmPicker.addDescriptiveActions(title: L10n.notOnWifi, message: warningMessage, icon: "option-alert", actions: [downloadAction, queueAction])
            }

            confirmPicker.show(statusBarStyle: self?.preferredStatusBarStyle ?? .default)
        }
        optionPicker.addAction(action: downloadAllAction)

        let unarchivedQuery = "SELECT COUNT(*) FROM \(DataManager.episodeTableName) WHERE podcast_id = ? AND archived = 0"
        let unarchivedCount = DataManager.sharedManager.count(query: unarchivedQuery, values: [podcast.id])
        if unarchivedCount > 0 {
            let archiveAllAction = OptionAction(label: L10n.podcastArchiveAll, icon: "podcast-archiveall") { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.confirmArchiveAll(episodeCount: unarchivedCount, playedOnly: false)
            }
            optionPicker.addAction(action: archiveAllAction)
        } else if !(podcast.autoArchiveEpisodeLimit > 0 && podcast.overrideGlobalArchive) {
            // we only show unarchive all for podcasts that haven't set an episode limit
            let unarchiveAllAction = OptionAction(label: L10n.podcastUnarchiveAll, icon: "list_unarchive") { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.performUnarchiveAll()
            }
            optionPicker.addAction(action: unarchiveAllAction)
        }

        let playedNotArchivedQuery = "SELECT COUNT(*) FROM \(DataManager.episodeTableName) WHERE podcast_id = ? AND archived = 0 AND playingStatus = \(PlayingStatus.completed.rawValue)"
        let playedNotArchivedCount = DataManager.sharedManager.count(query: playedNotArchivedQuery, values: [podcast.id])
        if playedNotArchivedCount > 0 {
            let archiveAllPlayedAction = OptionAction(label: L10n.podcastArchiveAllPlayed, icon: "podcast-archiveall") { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.confirmArchiveAll(episodeCount: playedNotArchivedCount, playedOnly: true)
            }
            optionPicker.addAction(action: archiveAllPlayedAction)
        }

        optionPicker.show(statusBarStyle: preferredStatusBarStyle)
        Analytics.track(.podcastScreenOptionsTapped)
    }

    private func performUnarchiveAll() {
        guard let podcastDelegate = podcastDelegate else { return }

        podcastDelegate.unarchiveAllTapped()
    }

    private func confirmArchiveAll(episodeCount: Int, playedOnly: Bool) {
        guard let podcastDelegate = podcastDelegate else { return }

        let archiveAllConfirm = OptionsPicker(title: nil)
        let archiveAllAction = OptionAction(label: episodeCount == 1 ? L10n.podcastArchiveEpisodeCountSingular : L10n.podcastArchiveEpisodesCountPluralFormat(episodeCount.localized()), icon: nil, action: {
            podcastDelegate.archiveAllTapped(playedOnly: playedOnly)
        })
        archiveAllAction.destructive = true
        let title = playedOnly ? L10n.podcastArchiveAllPlayed : L10n.podcastArchiveAll
        archiveAllConfirm.addDescriptiveActions(title: title, message: L10n.podcastArchivePromptMsg, icon: "options-archiveall", actions: [archiveAllAction])

        archiveAllConfirm.show(statusBarStyle: preferredStatusBarStyle)
    }

    private func presentSortOptions() {
        guard let podcast = podcastDelegate?.displayedPodcast() else { return }

        let optionPicker = OptionsPicker(title: L10n.podcastSortOrderTitle)

        let sortOrder = podcast.podcastSortOrder

        let newestToOldestAction = OptionAction(label: PodcastEpisodeSortOrder.newestToOldest.description, selected: sortOrder == PodcastEpisodeSortOrder.newestToOldest) { [weak self] in
            self?.setSortSetting(.newestToOldest)
            Analytics.track(.podcastsScreenSortOrderChanged, properties: ["sort_by": PodcastEpisodeSortOrder.newestToOldest])
        }

        optionPicker.addAction(action: newestToOldestAction)

        let oldestToNewestAction = OptionAction(label: PodcastEpisodeSortOrder.oldestToNewest.description, selected: sortOrder == PodcastEpisodeSortOrder.oldestToNewest) { [weak self] in
            self?.setSortSetting(.oldestToNewest)
            Analytics.track(.podcastsScreenSortOrderChanged, properties: ["sort_by": PodcastEpisodeSortOrder.oldestToNewest])
        }
        optionPicker.addAction(action: oldestToNewestAction)

        let shortestToLongestAction = OptionAction(label: PodcastEpisodeSortOrder.shortestToLongest.description, selected: sortOrder == PodcastEpisodeSortOrder.shortestToLongest) { [weak self] in
            self?.setSortSetting(.shortestToLongest)
            Analytics.track(.podcastsScreenSortOrderChanged, properties: ["sort_by": PodcastEpisodeSortOrder.shortestToLongest])

        }
        optionPicker.addAction(action: shortestToLongestAction)

        let longestToShortestAction = OptionAction(label: PodcastEpisodeSortOrder.longestToShortest.description, selected: sortOrder == PodcastEpisodeSortOrder.longestToShortest) { [weak self] in
            self?.setSortSetting(.longestToShortest)
            Analytics.track(.podcastsScreenSortOrderChanged, properties: ["sort_by": PodcastEpisodeSortOrder.longestToShortest])

        }
        optionPicker.addAction(action: longestToShortestAction)

        optionPicker.show(statusBarStyle: preferredStatusBarStyle)
    }

    private func presentGroupOptions() {
        guard let podcast = podcastDelegate?.displayedPodcast() else { return }

        let optionPicker = OptionsPicker(title: L10n.podcastGroupOptionsTitle)

        let noneAction = OptionAction(label: L10n.none, selected: podcast.episodeGrouping == PodcastGrouping.none.rawValue) { [weak self] in
            self?.setGroupingSetting(.none)
            Analytics.track(.podcastsScreenEpisodeGroupingChanged, properties: ["value": PodcastGrouping.none])

        }
        optionPicker.addAction(action: noneAction)

        let downloadedAction = OptionAction(label: L10n.statusDownloaded, selected: podcast.episodeGrouping == PodcastGrouping.downloaded.rawValue) { [weak self] in
            self?.setGroupingSetting(.downloaded)
            Analytics.track(.podcastsScreenEpisodeGroupingChanged, properties: ["value": PodcastGrouping.downloaded])

        }
        optionPicker.addAction(action: downloadedAction)

        let unplayedAction = OptionAction(label: L10n.statusUnplayed, selected: podcast.episodeGrouping == PodcastGrouping.unplayed.rawValue) { [weak self] in
            self?.setGroupingSetting(.unplayed)
            Analytics.track(.podcastsScreenEpisodeGroupingChanged, properties: ["value": PodcastGrouping.unplayed])

        }
        optionPicker.addAction(action: unplayedAction)

        let seasonAction = OptionAction(label: L10n.season, selected: podcast.episodeGrouping == PodcastGrouping.season.rawValue) { [weak self] in
            self?.setGroupingSetting(.season)
            Analytics.track(.podcastsScreenEpisodeGroupingChanged, properties: ["value": PodcastGrouping.season])

        }
        optionPicker.addAction(action: seasonAction)

        let starAction = OptionAction(label: L10n.statusStarred, selected: podcast.episodeGrouping == PodcastGrouping.starred.rawValue) { [weak self] in
            self?.setGroupingSetting(.starred)
            Analytics.track(.podcastsScreenEpisodeGroupingChanged, properties: ["value": PodcastGrouping.starred])

        }
        optionPicker.addAction(action: starAction)

        optionPicker.show(statusBarStyle: preferredStatusBarStyle)
    }

    func hideKeyboard() {
        searchTextField?.resignFirstResponder()
    }

    func searchDidComplete() {
        DispatchQueue.main.async { [weak self] in
            self?.handleSearchCompleted()
        }
    }

    func searchInProgress() -> Bool {
        searching
    }

    func searchBarActive() -> Bool {
        searchTextField?.isFirstResponder ?? false
    }

    private func setSortSetting(_ setting: PodcastEpisodeSortOrder) {
        guard let podcast = podcastDelegate?.displayedPodcast() else { return }
        if FeatureFlag.settingsSync.enabled {
            podcast.settings.episodesSortOrder = setting
            podcast.syncStatus = SyncStatus.notSynced.rawValue
        }
        podcast.episodeSortOrder = setting.rawValue
        DataManager.sharedManager.save(podcast: podcast)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast.uuid)
    }

    private func setGroupingSetting(_ setting: PodcastGrouping) {
        guard let podcast = podcastDelegate?.displayedPodcast() else { return }
        podcast.episodeGrouping = setting.rawValue
        DataManager.sharedManager.save(podcast: podcast)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast.uuid)
    }
}
