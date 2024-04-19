import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class FolderViewController: PCViewController, UIGestureRecognizerDelegate {
    @IBOutlet var mainGrid: UICollectionView! {
        didSet {
            registerCells()
        }
    }

    @IBOutlet var emptyFolderView: ThemeableView!
    @IBOutlet var emptyFolderTitle: ThemeableLabel! {
        didSet {
            emptyFolderTitle.text = L10n.folderEmptyTitle
        }
    }

    @IBOutlet var emptyFolderDescription: UILabel! {
        didSet {
            emptyFolderDescription.text = L10n.folderEmptyDescription
        }
    }

    @IBOutlet var emptyFolderImage: ThemeableImageView! {
        didSet {
            emptyFolderImage.imageStyle = .primaryIcon01
        }
    }

    var folder: Folder
    var podcasts: [Podcast] = []

    let gridHelper = GridHelper()

    private var lastWillLayoutWidth: CGFloat = 0

    init(folder: Folder) {
        self.folder = folder
        super.init(nibName: "FolderViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        customRightBtn = UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(folderOptionsTapped(_:)))
        customRightBtn?.accessibilityLabel = L10n.accessibilityMoreActions
        super.viewDidLoad()

        title = folder.name

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mainGrid.addGestureRecognizer(longPressGesture)
        longPressGesture.delegate = self

        miniPlayerStatusDidChange()

        gridHelper.configureLayout(collectionView: mainGrid)

        updateNavTintColor()
        reloadPodcasts()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if lastWillLayoutWidth != view.bounds.width {
            lastWillLayoutWidth = view.bounds.width
            updateFlowLayoutSize()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        reloadFolder()
        miniPlayerStatusDidChange()

        addCustomObserver(Constants.Notifications.podcastUpdated, selector: #selector(reloadFolder))
        addCustomObserver(Constants.Notifications.folderChanged, selector: #selector(reloadFolder))
        addCustomObserver(Constants.Notifications.miniPlayerDidAppear, selector: #selector(miniPlayerStatusDidChange))
        addCustomObserver(Constants.Notifications.miniPlayerDidDisappear, selector: #selector(miniPlayerStatusDidChange))

        Analytics.track(.folderShown, properties: ["number_of_podcasts": podcasts.count, "sort_order": folder.librarySort()])
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        removeAllCustomObservers()
    }

    private func updateNavTintColor() {
        let folderColor = AppTheme.folderColor(colorInt: folder.color)
        let titleColor = ThemeColor.filterText01(filterColor: folderColor)
        let iconColor = ThemeColor.filterIcon01(filterColor: folderColor)
        let backgroundColor = ThemeColor.filterUi01(filterColor: folderColor)

        changeNavTint(titleColor: titleColor, iconsColor: iconColor, backgroundColor: backgroundColor)
    }

    @IBAction func addPodcastsTapped(_ sender: Any) {
        showPodcastSelectionDialog()
        Analytics.track(.folderAddPodcastsButtonTapped)
    }

    @objc private func reloadFolder() {
        guard let updatedFolder = DataManager.sharedManager.findFolder(uuid: folder.uuid) else { return }

        folder = updatedFolder
        title = folder.name
        reloadPodcasts()

        updateNavTintColor()
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        gridHelper.handleLongPress(gesture, from: mainGrid, isList: Settings.libraryType() == .list, containerView: view)
    }

    @objc private func folderOptionsTapped(_ sender: UIBarButtonItem) {
        let optionsPicker = OptionsPicker(title: nil)

        let sortOption = folder.librarySort()
        let sortAction = OptionAction(label: L10n.sortBy, secondaryLabel: sortOption.description, icon: "podcast-sort") { [weak self] in
            self?.showSortOptions()
            Analytics.track(.folderOptionsModalOptionTapped, properties: ["option": "sort_by"])
        }
        optionsPicker.addAction(action: sortAction)

        let editAction = OptionAction(label: L10n.folderEdit, icon: "folder-edit") { [weak self] in
            guard let folder = self?.folder else { return }

            let model = FolderModel(saveOnChange: true)
            model.name = folder.name
            model.colorInt = Int(folder.color)
            model.folderUuid = folder.uuid
            let editFolderView = EditFolderView(model: model) { [weak self] shouldCloseFolder in
                self?.dismiss(animated: true) {
                    if shouldCloseFolder {
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
            let hostingController = PCHostingController(rootView: editFolderView.environmentObject(Theme.sharedTheme))

            self?.present(hostingController, animated: true, completion: nil)

            Analytics.track(.folderOptionsModalOptionTapped, properties: ["option": "edit_folder"])
        }
        optionsPicker.addAction(action: editAction)

        let addRemoveAction = OptionAction(label: L10n.folderAddRemovePodcasts, icon: "folder-podcasts") { [weak self] in
            guard let self = self else { return }

            self.showPodcastSelectionDialog()

            Analytics.track(.folderOptionsModalOptionTapped, properties: ["option": "add_or_remove_podcasts"])
        }
        optionsPicker.addAction(action: addRemoveAction)

        optionsPicker.show(statusBarStyle: preferredStatusBarStyle)

        Analytics.track(.folderOptionsButtonTapped)
    }

    private func showPodcastSelectionDialog() {
        let model = FolderModel(saveOnChange: true)
        model.name = folder.name
        model.colorInt = Int(folder.color)
        model.selectedPodcastUuids = podcasts.map(\.uuid)
        model.folderUuid = folder.uuid
        let editFoldersView = EditFolderPodcastsView(model: model) { [weak self] in
            self?.dismiss(animated: true)
        }
        let hostingController = PCHostingController(rootView: editFoldersView.environmentObject(Theme.sharedTheme))

        present(hostingController, animated: true, completion: nil)
    }

    private func showSortOptions() {
        let options = OptionsPicker(title: L10n.sortBy.localizedUppercase)

        let sortOption = folder.librarySort()
        let podcastNameAction = OptionAction(label: LibrarySort.titleAtoZ.description, selected: sortOption == .titleAtoZ) { [weak self] in
            self?.changeSortOrder(.titleAtoZ)
        }
        options.addAction(action: podcastNameAction)

        let releaseDateAction = OptionAction(label: LibrarySort.episodeDateNewestToOldest.description, selected: sortOption == .episodeDateNewestToOldest) { [weak self] in
            self?.changeSortOrder(.episodeDateNewestToOldest)
        }
        options.addAction(action: releaseDateAction)

        let subscribedOrder = OptionAction(label: LibrarySort.dateAddedNewestToOldest.description, selected: sortOption == .dateAddedNewestToOldest) { [weak self] in
            self?.changeSortOrder(.dateAddedNewestToOldest)
        }
        options.addAction(action: subscribedOrder)

        let dragAndDropAction = OptionAction(label: LibrarySort.custom.description, selected: sortOption == .custom) { [weak self] in
            self?.changeSortOrder(.custom)
        }
        options.addAction(action: dragAndDropAction)

        options.show(statusBarStyle: preferredStatusBarStyle)
    }

    private func changeSortOrder(_ order: LibrarySort.Old) {
        folder.sortType = Int32(order.rawValue)
        folder.syncModified = TimeFormatter.currentUTCTimeInMillis()
        DataManager.sharedManager.save(folder: folder)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderChanged, object: folder.uuid)

        Analytics.track(.folderSortByChanged, properties: ["sort_order": order])
    }

    @objc private func miniPlayerStatusDidChange() {
        let horizontalMargin: CGFloat = Settings.libraryType() == .list ? 0 : 16
        let bottomMargin: CGFloat = PlaybackManager.shared.currentEpisode() == nil ? 0 : Constants.Values.miniPlayerOffset + 8
        mainGrid.contentInset = UIEdgeInsets(top: mainGrid.contentInset.top, left: horizontalMargin, bottom: bottomMargin, right: horizontalMargin)
    }

    // TODO: change this to be diff based and see if we can use the new iOS diffable stuff
    private func reloadPodcasts() {
        podcasts = DataManager.sharedManager.allPodcastsInFolder(folder: folder)

        let badgeType = Settings.podcastBadgeType()
        // load the required badge information if the supplied badge type needs it
        if badgeType == .allUnplayed {
            let podcastCounts = DataManager.sharedManager.podcastUnfinishedCounts()
            for podcast in podcasts {
                podcast.cachedUnreadCount = Int(podcastCounts[podcast.uuid] ?? 0)
            }
        } else if badgeType == .latestEpisode {
            for podcast in podcasts {
                if let latestEpisode = DataManager.sharedManager.findLatestEpisode(podcast: podcast) {
                    podcast.cachedUnreadCount = latestEpisode.unplayed() && !latestEpisode.archived ? 1 : 0
                } else {
                    podcast.cachedUnreadCount = 0
                }
            }
        }

        mainGrid.reloadData()
        emptyFolderView.isHidden = podcasts.count > 0
    }
}
