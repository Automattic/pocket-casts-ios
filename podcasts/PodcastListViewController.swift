import DifferenceKit
import PocketCastsDataModel
import PocketCastsServer
import UIKit

class PodcastListViewController: PCViewController, UIGestureRecognizerDelegate, ShareListDelegate {
    let gridHelper = GridHelper()
    
    @IBOutlet var addPodcastBtn: ThemeableButton! {
        didSet {
            addPodcastBtn.buttonTitle = L10n.podcastGridDiscoverPodcasts
            addPodcastBtn.buttonTapped = {
                NavigationManager.sharedManager.navigateTo(NavigationManager.discoverPageKey, data: nil)
            }
        }
    }
    
    @IBOutlet var noPodcastsIcon: ThemeableImageView! {
        didSet {
            noPodcastsIcon.imageStyle = .primaryIcon01
        }
    }

    @IBOutlet var noPodcastsView: UIView!
    @IBOutlet var noPodcastsMessage: ThemeableLabel! {
        didSet {
            noPodcastsMessage.style = .primaryText02
            noPodcastsMessage.text = L10n.podcastGridNoPodcastsMsg
        }
    }
    
    @IBOutlet var podcastsCollectionView: UICollectionView! {
        didSet {
            registerCells()
            
            if let layout = podcastsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.sectionHeadersPinToVisibleBounds = true
            }
        }
    }
    
    @IBOutlet var noPodcastsTitle: ThemeableLabel! {
        didSet {
            noPodcastsTitle.text = L10n.podcastGridNoPodcastsTitle
        }
    }
    
    var gridItems = [HomeGridListItem]()
    
    private var lastWillLayoutWidth: CGFloat = 0

    private var homeGridDataHelper = HomeGridDataHelper()
    
    private lazy var refreshQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        return queue
    }()
    
    var searchController: PCSearchBarController!
    var searchResultsControler: PodcastListSearchResultsController!
    
    override func viewDidLoad() {
        customRightBtn = UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(podcastOptionsTapped(_:)))
        customRightBtn?.accessibilityLabel = L10n.accessibilityMoreActions
        super.viewDidLoad()
        
        updateFolderButton()
        
        title = L10n.podcastsPlural
        setupSearchBar()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        podcastsCollectionView.addGestureRecognizer(longPressGesture)
        longPressGesture.delegate = self
        
        gridHelper.configureLayout(collectionView: podcastsCollectionView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        miniPlayerStatusDidChange()
        refreshGridItems()
        addEventObservers()
        updateForVoiceOver()
        updateFolderButton()

        Analytics.track(.podcastsListShown, properties: [
            "sort_order": Settings.homeFolderSortOrder().analyticsDescription,
            "badge_type": Settings.podcastBadgeType().analyticsDescription,
            "layout": Settings.libraryType().analyticsDescription,
            "number_of_podcasts": homeGridDataHelper.numberOfPodcasts,
            "number_of_folders": homeGridDataHelper.numberOfFolders
        ])
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if lastWillLayoutWidth != view.bounds.width {
            lastWillLayoutWidth = view.bounds.width
            updateFlowLayoutSize()
        }
    }
    
    override func handleAppWillBecomeActive() {
        refreshGridItems()
        addEventObservers()
    }
    
    override func handleAppDidEnterBackground() {
        removeAllCustomObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        navigationController?.navigationBar.shadowImage = nil
        removeAllCustomObservers()
    }
    
    private func addEventObservers() {
        addCustomObserver(ServerNotifications.podcastsRefreshed, selector: #selector(refreshGridItems))
        addCustomObserver(ServerNotifications.subscriptionStatusChanged, selector: #selector(subscriptionStatusDidChange))
        addCustomObserver(Constants.Notifications.podcastAdded, selector: #selector(refreshGridItems))
        addCustomObserver(Constants.Notifications.podcastDeleted, selector: #selector(refreshGridItems))
        addCustomObserver(Constants.Notifications.opmlImportCompleted, selector: #selector(refreshGridItems))
        addCustomObserver(ServerNotifications.syncCompleted, selector: #selector(refreshGridItems))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(refreshGridItems))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(refreshGridItems))
        
        addCustomObserver(Constants.Notifications.folderChanged, selector: #selector(refreshGridItems))
        addCustomObserver(Constants.Notifications.folderDeleted, selector: #selector(refreshGridItems))
        
        addCustomObserver(Constants.Notifications.miniPlayerDidAppear, selector: #selector(miniPlayerStatusDidChange))
        addCustomObserver(Constants.Notifications.miniPlayerDidDisappear, selector: #selector(miniPlayerStatusDidChange))
        
        addCustomObserver(Constants.Notifications.tappedOnSelectedTab, selector: #selector(checkForScrollTap(_:)))
        addCustomObserver(Constants.Notifications.searchRequested, selector: #selector(searchRequested))
        
        addCustomObserver(UIAccessibility.voiceOverStatusDidChangeNotification, selector: #selector(updateForVoiceOver))
    }
    
    @objc private func subscriptionStatusDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.updateFolderButton()
        }
    }
    
    private func updateFolderButton() {
        let folderImage = SubscriptionHelper.hasActiveSubscription() ? UIImage(named: "folder-create") : UIImage(named: AppTheme.folderLockedImageName())
        let leftButton = UIBarButtonItem(image: folderImage, style: .plain, target: self, action: #selector(createFolderTapped(_:)))
        leftButton.accessibilityLabel = L10n.folderCreateNew
        navigationItem.leftBarButtonItem = leftButton
    }
    
    @objc private func updateForVoiceOver() {
        // if a user turns voice over on, show them the search field that's hidden behind a scroll
        if UIAccessibility.isVoiceOverRunning {
            if podcastsCollectionView.contentOffset.y == 0 {
                podcastsCollectionView.contentOffset.y = -searchController.view.bounds.height
            }
        }
    }
    
    @objc private func checkForScrollTap(_ notification: Notification) {
        let topOffset = view.safeAreaInsets.top
        if let index = notification.object as? Int, index == tabBarItem.tag, podcastsCollectionView.contentOffset.y > -topOffset {
            podcastsCollectionView.setContentOffset(CGPoint(x: 0, y: -topOffset), animated: true)
        }
    }
    
    @objc private func searchRequested() {
        let topOffset = view.safeAreaInsets.top
        podcastsCollectionView.setContentOffset(CGPoint(x: 0, y: -searchController.view.bounds.height - topOffset), animated: false)
        searchController.searchTextField.becomeFirstResponder()
    }
    
    @objc private func miniPlayerStatusDidChange() {
        if PlaybackManager.shared.currentEpisode() != nil {
            podcastsCollectionView.contentInset = UIEdgeInsets(top: podcastsCollectionView.contentInset.top, left: 0, bottom: Constants.Values.miniPlayerOffset, right: 0)
        }
        else {
            podcastsCollectionView.contentInset = UIEdgeInsets(top: podcastsCollectionView.contentInset.top, left: 0, bottom: 0, right: 0)
        }
    }
    
    @objc func refreshGridItems() {
        refreshQueue.addOperation { [weak self] in
            guard let strongSelf = self else { return }
            
            let oldData = strongSelf.gridItems
            let newData = HomeGridDataHelper.gridListItems(orderedBy: Settings.homeFolderSortOrder(), badgeType: Settings.podcastBadgeType())
            
            DispatchQueue.main.sync {
                let stagedSet = StagedChangeset(source: oldData, target: newData)
                strongSelf.podcastsCollectionView.reload(using: stagedSet, setData: { data in
                    strongSelf.gridItems = data
                })
                strongSelf.noPodcastsView.isHidden = newData.count != 0 || SyncManager.isFirstSyncInProgress()
            }
        }
    }
    
    @objc private func createFolderTapped(_ sender: UIBarButtonItem) {
        if !SubscriptionHelper.hasActiveSubscription() {
            NavigationManager.sharedManager.showUpsellView(from: self, source: .folders)
            return
        }
        
        let creatFolderView = CreateFolderView { [weak self] folderUuid in
            if let folderUuid = folderUuid, let folder = DataManager.sharedManager.findFolder(uuid: folderUuid) {
                self?.dismiss(animated: true, completion: {
                    NavigationManager.sharedManager.navigateTo(NavigationManager.folderPageKey, data: [NavigationManager.folderKey: folder])
                })
            }
            else {
                self?.dismiss(animated: true, completion: nil)
            }
        }
        let hostingController = PCHostingController(rootView: creatFolderView.environmentObject(Theme.sharedTheme))
        
        present(hostingController, animated: true, completion: nil)
        AnalyticsHelper.folderCreated()
        Analytics.track(.podcastsListFolderButtonTapped)
    }
    
    @objc private func podcastOptionsTapped(_ sender: UIBarButtonItem) {
        let optionsPicker = OptionsPicker(title: nil)
        
        let sortOption = Settings.homeFolderSortOrder()
        let sortAction = OptionAction(label: L10n.sortBy, secondaryLabel: sortOption.description, icon: "podcast-sort") { [weak self] in
            self?.showSortOrderOptions()
            Analytics.track(.podcastsListModalOptionTapped, properties: ["option": "sort_by"])
        }
        optionsPicker.addAction(action: sortAction)
        
        let largeGridAction = OptionAction(label: L10n.podcastsLargeGrid, icon: "podcastlist_largegrid", selected: Settings.libraryType() == .threeByThree) { [weak self] in
            Settings.setLibraryType(.threeByThree)
            self?.gridTypeChanged()
            Analytics.track(.podcastsListModalOptionTapped, properties: ["option": "layout"])
            Analytics.track(.podcastsListLayoutChanged, properties: ["layout": LibraryType.threeByThree.analyticsDescription])
        }
        let smallGridAction = OptionAction(label: L10n.podcastsSmallGrid, icon: "podcastlist_smallgrid", selected: Settings.libraryType() == .fourByFour) { [weak self] in
            Settings.setLibraryType(.fourByFour)
            self?.gridTypeChanged()
            Analytics.track(.podcastsListModalOptionTapped, properties: ["option": "layout"])
            Analytics.track(.podcastsListLayoutChanged, properties: ["layout": LibraryType.fourByFour.analyticsDescription])
        }
        let listGridAction = OptionAction(label: L10n.podcastsList, icon: "podcastlist_listview", selected: Settings.libraryType() == .list) { [weak self] in
            Settings.setLibraryType(.list)
            self?.gridTypeChanged()
            Analytics.track(.podcastsListModalOptionTapped, properties: ["option": "layout"])
            Analytics.track(.podcastsListLayoutChanged, properties: ["layout": LibraryType.list.analyticsDescription])
        }
        optionsPicker.addSegmentedAction(name: L10n.podcastsLayout, icon: "podcastlist_largegrid", actions: [largeGridAction, smallGridAction, listGridAction])
        
        let badgeType = Settings.podcastBadgeType()
        let badgesAction = OptionAction(label: L10n.podcastsBadges, secondaryLabel: badgeType.description, icon: "badges") { [weak self] in
            self?.showBadgeOptions()
            Analytics.track(.podcastsListModalOptionTapped, properties: ["option": "badges"])
        }
        optionsPicker.addAction(action: badgesAction)
        
        let shareAction = OptionAction(label: L10n.podcastsShare, icon: "podcast-share") {
            let shareController = SharePodcastsViewController()
            shareController.delegate = self
            let navController = SJUIUtils.navController(for: shareController)
            self.present(navController, animated: true, completion: nil)
            Analytics.track(.podcastsListModalOptionTapped, properties: ["option": "share"])
        }
        optionsPicker.addAction(action: shareAction)
        
        optionsPicker.show(statusBarStyle: preferredStatusBarStyle)

        Analytics.track(.podcastsListOptionsButtonTapped)
    }
    
    // MARK: - ShareListDelegate
    
    func shareUrlAvailable(_ shareUrl: String, listName: String) {
        SharingHelper.shared.shareLinkToPodcastList(name: listName, url: shareUrl, fromController: self, barButtonItem: customRightBtn, completionHandler: nil)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        gridHelper.handleLongPress(gesture, from: podcastsCollectionView, isList: Settings.libraryType() == .list, containerView: view)
    }
    
    func itemCount() -> Int {
        gridItems.count
    }
    
    func podcastAt(indexPath: IndexPath) -> Podcast? {
        gridItems[safe: indexPath.row]?.podcast
    }
    
    func folderAt(indexPath: IndexPath) -> Folder? {
        gridItems[safe: indexPath.row]?.folder
    }
    
    func itemAt(indexPath: IndexPath) -> HomeGridListItem? {
        gridItems[safe: indexPath.row]
    }
    
    func gridTypeChanged() {
        podcastsCollectionView.reloadData()
    }
    
    private func showBadgeOptions() {
        let options = OptionsPicker(title: L10n.podcastsBadges.localizedUppercase)
        
        let badgeOption = Settings.podcastBadgeType()
        
        let badgeOffAction = OptionAction(label: BadgeType.off.description, selected: badgeOption == .off) { [weak self] in
            guard let strongSelf = self else { return }
            
            Settings.setPodcastBadgeType(.off)
            strongSelf.refreshGridItems()
            Analytics.track(.podcastsListBadgesChanged, properties: ["type": BadgeType.off.analyticsDescription])
        }
        options.addAction(action: badgeOffAction)
        
        let latestEpisodeAction = OptionAction(label: BadgeType.allUnplayed.description, selected: badgeOption == .allUnplayed) { [weak self] in
            guard let strongSelf = self else { return }
            
            Settings.setPodcastBadgeType(.allUnplayed)
            strongSelf.refreshGridItems()
            Analytics.track(.podcastsListBadgesChanged, properties: ["type": BadgeType.allUnplayed.analyticsDescription])
        }
        options.addAction(action: latestEpisodeAction)
        
        let unplayedCountAction = OptionAction(label: BadgeType.latestEpisode.description, selected: badgeOption == .latestEpisode) { [weak self] in
            guard let strongSelf = self else { return }
            
            Settings.setPodcastBadgeType(.latestEpisode)
            strongSelf.refreshGridItems()
        }
        options.addAction(action: unplayedCountAction)
        
        options.show(statusBarStyle: preferredStatusBarStyle)
    }
}
