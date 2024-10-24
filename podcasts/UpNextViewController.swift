import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class UpNextViewController: UIViewController, UIGestureRecognizerDelegate {
    static let playerCell = "PlayerCell"
    static let noUpNextCell = "NothingUpNextCell"
    static let nowPlayingCell = "UpNextNowPlayingCell"
    static let upNextSection = 1
    static let upNextRowHeight: CGFloat = 72
    static let noUpNextRowHeight: CGFloat = 180
    static let nowPlayingRowHeight: CGFloat = 72
    static let rearrangeWidth: CGFloat = 60
    static let bottomMargin: CGFloat = 8

    enum sections: Int { case nowPlayingSection = 0, upNextSection }

    var tableData = [sections]()

    var themeOverride: Theme.ThemeType? = nil

    lazy var contentInseter = {
        InsetAdjuster(ignoreMiniPlayer: !self.showingInTab)
    }()

    var isMultiSelectEnabled = false {
        didSet {
            let didChange = oldValue != isMultiSelectEnabled

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateNavBarButtons()
                contentInseter.isMultiSelectEnabled = isMultiSelectEnabled
                if !self.isMultiSelectEnabled {
                    self.multiSelectActionBar.isHidden = true
                    self.selectedPlayListEpisodes.removeAll()
                    if didChange {
                        self.track(.upNextMultiSelectExited)
                    }
                } else {
                    self.track(.upNextMultiSelectEntered)
                }
                if self.showingInTab {
                    self.multiSelectActionBarBottomConstraint.constant = PlaybackManager.shared.currentEpisode() == nil ? Self.bottomMargin : Constants.Values.miniPlayerOffset + Self.bottomMargin
                }
                reloadTable()
            }
        }
    }

    var changedViaSwipeToRemove = false

    let remainingLabel = ThemeableLabel()
    let shuffleButton = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
    let clearQueueButton = UIButton(frame: CGRect(x: 0, y: 0, width: 93, height: 16))
    var selectedPlayListEpisodes = [PlaylistEpisode]() {
        didSet {
            multiSelectActionBar.setSelectedCount(count: selectedPlayListEpisodes.count)
            if selectedPlayListEpisodes.count == 0 {
                contentInseter.isMultiSelectEnabled = false
            } else {
                contentInseter.isMultiSelectEnabled = true
            }
            updateNavBarButtons()
        }
    }

    var multiSelectGestureInProgress = false
    var isReorderInProgress = false

    @IBOutlet var upNextTable: ThemeableTable! {
        didSet {
            upNextTable.themeOverride = themeOverride
            upNextTable.register(UINib(nibName: "PlayerCell", bundle: nil), forCellReuseIdentifier: UpNextViewController.playerCell)
            upNextTable.register(UINib(nibName: "NothingUpNextCell", bundle: nil), forCellReuseIdentifier: UpNextViewController.noUpNextCell)
            upNextTable.register(UINib(nibName: "UpNextNowPlayingCell", bundle: nil), forCellReuseIdentifier: UpNextViewController.nowPlayingCell)
            upNextTable.backgroundView = nil
            upNextTable.isEditing = true
            upNextTable.addGestureRecognizer(customLongPressGesture)
            upNextTable.allowsMultipleSelectionDuringEditing = true
            upNextTable.allowsMultipleSelection = true
        }
    }

    @IBOutlet var multiSelectActionBar: MultiSelectFooterView! {
        didSet {
            multiSelectActionBar.delegate = self
            multiSelectActionBar.getActionsFunc = Settings.upNextMultiSelectActions
            multiSelectActionBar.setActionsFunc = Settings.updateUpNextMultiSelectActions
            multiSelectActionBar.themeOverride = themeOverride
        }
    }

    @IBOutlet var multiSelectActionBarBottomConstraint: NSLayoutConstraint!

    lazy var customLongPressGesture: UILongPressGestureRecognizer = {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tableLongPressed(_:)))
        longPressRecognizer.delegate = self

        return longPressRecognizer
    }()

    let source: UpNextViewSource
    let showingInTab: Bool

    init(source: UpNextViewSource, themeOverride: Theme.ThemeType? = nil, showingInTab: Bool = false) {
        self.source = source
        self.themeOverride = !showingInTab && Settings.darkUpNextTheme ? .dark : themeOverride
        self.showingInTab = showingInTab
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.upNext

        (view as? ThemeableView)?.style = .primaryUi04
        (view as? ThemeableView)?.themeOverride = themeOverride

        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.playbackTrackChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.playbackEnded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.upNextQueueChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.upNextEpisodeAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.upNextEpisodeRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTimeRemainingLabel), name: Constants.Notifications.playbackProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reorderingDidBegin), name: .tableViewReorderWillBegin, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reorderingDidEnd), name: .tableViewReorderDidEnd, object: nil)

        if FeatureFlag.upNextShuffle.enabled, showingInTab {
            NotificationCenter.default.addObserver(self, selector: #selector(updateShuffleButtonState), name: Constants.Notifications.upNextShuffleToggle, object: nil)
        }

        remainingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        remainingLabel.adjustsFontSizeToFitWidth = true
        remainingLabel.minimumScaleFactor = 0.8
        remainingLabel.numberOfLines = 2
        remainingLabel.style = .primaryText02
        remainingLabel.themeOverride = themeOverride

        if FeatureFlag.upNextShuffle.enabled {
            NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
            themeDidChange()
            shuffleButton.isSelected = Settings.upNextShuffleEnabled()
            shuffleButton.addTarget(self, action: #selector(shuffleButtonTapped), for: .touchUpInside)
        } else {
            clearQueueButton.setTitle(L10n.queueClearQueue, for: .normal)
            clearQueueButton.setTitleColor(AppTheme.colorForStyle(.primaryText02, themeOverride: themeOverride), for: .normal)
            clearQueueButton.setTitleColor(AppTheme.colorForStyle(.primaryText02, themeOverride: themeOverride).withAlphaComponent(0.5), for: .disabled)
            clearQueueButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
            clearQueueButton.addTarget(self, action: #selector(clearQueueTapped), for: .touchUpInside)
        }

        contentInseter.setupInsetAdjustmentsForMiniPlayer(scrollView: upNextTable)

        refreshSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavBarButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // fix issues with the now playing cell not animating by reloading it on appear
        reloadTable()

        track(.upNextShown, properties: ["source": source])

        AnalyticsHelper.upNextOpened()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard isViewLoaded else { return } // This method was called as a result of `setSelectedIndex` on UITabBarController. The view is not loaded at this point so we don't need to do anything to reset.
        selectedPlayListEpisodes.removeAll()
        isMultiSelectEnabled = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        track(.upNextDismissed)
    }

    @objc func clearQueueTapped() {
        let queueCount = PlaybackManager.shared.queue.upNextCount()

        if queueCount <= Constants.Limits.upNextClearWithoutWarning && !FeatureFlag.upNextShuffle.enabled {
            performClearAll()
        } else {
            let clearOptions = OptionsPicker(title: nil, themeOverride: themeOverride)
            let actionLabel = actionLabelText(queueCount)
            let clearAllAction = OptionAction(label: actionLabel, icon: nil, action: { [weak self] in
                self?.performClearAll()
            })
            clearAllAction.destructive = true
            clearOptions.addDescriptiveActions(title: L10n.clearUpNext, message: L10n.clearUpNextMessage, icon: "option-clear", actions: [clearAllAction])

            clearOptions.show(statusBarStyle: preferredStatusBarStyle)
        }

        selectedPlayListEpisodes.removeAll()
        isMultiSelectEnabled = false
    }

    @objc private func shuffleButtonTapped() {
        Settings.upNextShuffleToggle()
        if !showingInTab {
            updateShuffleButtonState()
        }
        track(.upNextShuffleToggled, properties: ["enabled": Settings.upNextShuffleEnabled()])
    }

    @objc private func themeDidChange() {
        let unselected = UIImage(named: "shuffle")?.withTintColor(AppTheme.colorForStyle(.primaryIcon02, themeOverride: themeOverride), renderingMode: .alwaysOriginal)
        let selected = UIImage(named: "shuffle-enabled")?.withTintColor(AppTheme.colorForStyle(.primaryIcon01, themeOverride: themeOverride), renderingMode: .alwaysOriginal)
        shuffleButton.setImage(unselected, for: .normal)
        shuffleButton.setImage(selected, for: .selected)
    }

    @objc private func updateShuffleButtonState() {
        shuffleButton.isSelected = Settings.upNextShuffleEnabled()
    }

    private func actionLabelText(_ queueCount: Int) -> String {
        if FeatureFlag.upNextShuffle.enabled, queueCount == 1 {
            return L10n.queueClearEpisodeQueueSingular
        }
        return L10n.queueClearEpisodeQueuePlural(queueCount.localized())
    }

    private func performClearAll() {
        PlaybackManager.shared.queue.clearUpNextList()
        reloadTable()
        track(.upNextQueueCleared)
    }

    var userEpisodeDetailVC: UserEpisodeDetailViewController?

    func showEpisodeDetailViewController(for episode: BaseEpisode?) {
        if let episode = episode as? Episode, let parentPodcast = episode.parentPodcast() {
            let episodeController = EpisodeDetailViewController(episode: episode, podcast: parentPodcast, source: .upNext)
            episodeController.modalPresentationStyle = .formSheet
            episodeController.themeOverride = themeOverride
            present(episodeController, animated: true, completion: nil)
        } else if let userEpisode = episode as? UserEpisode {
            if let fullEpisode = DataManager.sharedManager.findUserEpisode(uuid: userEpisode.uuid) {
                userEpisodeDetailVC = UserEpisodeDetailViewController(episode: fullEpisode)
                userEpisodeDetailVC?.delegate = self
                userEpisodeDetailVC?.themeOverride = themeOverride
                userEpisodeDetailVC?.animateIn()
            }
        }
    }

    @objc func updateTimeRemainingLabel() {
        var totalDuration = PlaybackManager.shared.queue.upNextTotalDuration(includePlayingEpisode: false)
        if let episode = PlaybackManager.shared.currentEpisode() {
            totalDuration += episode.duration.seconds - PlaybackManager.shared.currentTime()
        }
        remainingLabel.text = L10n.queueTotalTimeRemaining(TimeFormatter.shared.multipleUnitFormattedShortTime(time: totalDuration))
    }

    // MARK: - UIGestureRecongizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer != customLongPressGesture { return true }

        let touchPoint = gestureRecognizer.location(in: upNextTable)
        return touchPoint.x < (view.bounds.width - UpNextViewController.rearrangeWidth)
    }

    // MARK: - Nav bar actions

    @objc func doneTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func selectTapped() {
        isMultiSelectEnabled = true
    }

    @objc func selectAllTapped() {
        guard DataManager.sharedManager.allUpNextEpisodes().count > 1 else { return }
        upNextTable.selectAllBelow(indexPath: IndexPath(row: 0, section: sections.upNextSection.rawValue))

        track(.upNextSelectAllButtonTapped, properties: ["select_all": true])
        updateNavBarButtons()
    }

    @objc func cancelTapped() {
        isMultiSelectEnabled = false
    }

    @objc func deselectAllTapped() {
        upNextTable.deselectAll()
        track(.upNextSelectAllButtonTapped, properties: ["select_all": false])
    }

    func updateNavBarButtons() {
        navigationController?.navigationBar.tintColor = AppTheme.navBarIconsColor(themeOverride: themeOverride)
        if isMultiSelectEnabled {
            if MultiSelectHelper.shouldSelectAll(onCount: selectedPlayListEpisodes.count, totalCount: PlaybackManager.shared.queue.upNextCount()) {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.selectAll, style: .plain, target: self, action: #selector(selectAllTapped))
            } else {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.deselectAll, style: .plain, target: self, action: #selector(deselectAllTapped))
            }
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.cancel, style: .plain, target: self, action: #selector(cancelTapped))
        } else if !isMultiSelectEnabled, PlaybackManager.shared.queue.upNextCount() > 0 {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.select, style: .plain, target: self, action: #selector(selectTapped))
            if showingInTab {
                if FeatureFlag.upNextShuffle.enabled {
                    navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.clear, style: .plain, target: self, action: #selector(clearQueueTapped))
                    navigationItem.leftBarButtonItem?.isEnabled = PlaybackManager.shared.queue.upNextCount() > 0
                } else {
                    navigationItem.leftBarButtonItem = nil
                }
            } else {
                navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.done, style: .plain, target: self, action: #selector(doneTapped))
            }
        } else {
            navigationItem.rightBarButtonItem = nil
            if showingInTab {
                navigationItem.leftBarButtonItem = nil
            } else {
                navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.done, style: .plain, target: self, action: #selector(doneTapped))
            }
        }
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}

// MARK: - Reordering Notifications

extension UpNextViewController {
    @objc func reorderingDidBegin() {
        isReorderInProgress = true
    }

    @objc func reorderingDidEnd() {
        isReorderInProgress = false
    }
}

// MARK: - Analytics

extension UpNextViewController {
    func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        let defaultProperties: [String: Any] = ["source": source]
        let props = defaultProperties.merging(properties ?? [:]) { current, _ in current }

        Analytics.track(event, properties: props)
    }
}

enum UpNextViewSource: String, AnalyticsDescribable {
    case miniPlayer = "mini_player"
    case nowPlaying = "now_playing"
    case player
    case lockScreenWidget = "lock_screen_widget"
    case tabBar = "tab_bar"
    case unknown

    var analyticsDescription: String { rawValue }
}

extension UpNextViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .upNext
    }
}
