import MaterialComponents.MaterialBottomSheet
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

    enum sections: Int { case nowPlayingSection = 0, upNextSection }

    var tableData = [sections]()

    var themeOverride: Theme.ThemeType? = nil

    var isMultiSelectEnabled = false {
        didSet {
            let didChange = oldValue != isMultiSelectEnabled

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateNavBarButtons()
                if !self.isMultiSelectEnabled {
                    self.multiSelectActionBar.isHidden = true
                    self.selectedPlayListEpisodes.removeAll()
                    if didChange {
                        self.track(.upNextMultiSelectExited)
                    }
                } else {
                    self.track(.upNextMultiSelectEntered)
                }

                reloadTable()
            }
        }
    }

    var changedViaSwipeToRemove = false

    let remainingLabel = ThemeableLabel()
    let clearQueueButton = UIButton(frame: CGRect(x: 0, y: 0, width: 93, height: 16))
    var selectedPlayListEpisodes = [PlaylistEpisode]() {
        didSet {
            multiSelectActionBar.setSelectedCount(count: selectedPlayListEpisodes.count)
            if selectedPlayListEpisodes.count == 0 {
                upNextTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            } else {
                upNextTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
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

    init(source: UpNextViewSource, themeOverride: Theme.ThemeType? = nil) {
        self.source = source
        self.themeOverride = Settings.darkUpNextTheme ? .dark : themeOverride

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        track(.upNextShown, properties: ["source": source])

        title = L10n.upNext

        (view as? ThemeableView)?.style = .primaryUi04
        (view as? ThemeableView)?.themeOverride = themeOverride

        updateNavBarButtons()

        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.playbackTrackChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.playbackEnded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.upNextQueueChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.upNextEpisodeAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.upNextEpisodeRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTimeRemainingLabel), name: Constants.Notifications.playbackProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reorderingDidBegin), name: .tableViewReorderWillBegin, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reorderingDidEnd), name: .tableViewReorderDidEnd, object: nil)

        remainingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        remainingLabel.adjustsFontSizeToFitWidth = true
        remainingLabel.minimumScaleFactor = 0.8
        remainingLabel.numberOfLines = 2
        remainingLabel.style = .primaryText02
        remainingLabel.themeOverride = themeOverride

        clearQueueButton.setTitle(L10n.queueClearQueue, for: .normal)
        clearQueueButton.setTitleColor(AppTheme.colorForStyle(.primaryText02, themeOverride: themeOverride), for: .normal)
        clearQueueButton.setTitleColor(AppTheme.colorForStyle(.primaryText02, themeOverride: themeOverride).withAlphaComponent(0.5), for: .disabled)
        clearQueueButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        clearQueueButton.addTarget(self, action: #selector(clearQueueTapped), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // fix issues with the now playing cell not animating by reloading it on appear
        reloadTable()

        AnalyticsHelper.upNextOpened()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        selectedPlayListEpisodes.removeAll()
        isMultiSelectEnabled = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        track(.upNextDismissed)
    }

    @objc func clearQueueTapped() {
        let queueCount = PlaybackManager.shared.queue.upNextCount()

        if queueCount <= Constants.Limits.upNextClearWithoutWarning {
            performClearAll()
        } else {
            let clearOptions = OptionsPicker(title: nil, themeOverride: themeOverride)
            let actionLabel = L10n.queueClearEpisodeQueuePlural(queueCount.localized())
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
        if isMultiSelectEnabled {
            if MultiSelectHelper.shouldSelectAll(onCount: selectedPlayListEpisodes.count, totalCount: PlaybackManager.shared.queue.upNextCount()) {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.selectAll, style: .plain, target: self, action: #selector(selectAllTapped))
            } else {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.deselectAll, style: .plain, target: self, action: #selector(deselectAllTapped))
            }
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.cancel, style: .plain, target: self, action: #selector(cancelTapped))
        } else if !isMultiSelectEnabled, PlaybackManager.shared.queue.upNextCount() > 0 {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.select, style: .plain, target: self, action: #selector(selectTapped))
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.done, style: .plain, target: self, action: #selector(doneTapped))
        } else {
            navigationItem.rightBarButtonItem = nil
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.done, style: .plain, target: self, action: #selector(doneTapped))
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
    case unknown

    var analyticsDescription: String { rawValue }
}

extension UpNextViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .upNext
    }
}
