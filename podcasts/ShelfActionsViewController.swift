import MaterialComponents.MaterialBottomSheet
import UIKit

class ShelfActionsViewController: UIViewController {
    @IBOutlet var actionsTable: UITableView! {
        didSet {
            registerCells()
            actionsTable.isScrollEnabled = false
            actionsTable.backgroundView = nil

            actionsTable.separatorColor = AppTheme.tableDividerColor(for: .dark)
            actionsTable.indicatorStyle = AppTheme.indicatorStyle()
        }
    }

    @IBOutlet var headingView: UIView!
    @IBOutlet var headingViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var headingLabel: ThemeableLabel! {
        didSet {
            headingLabel.style = .playerContrast02
            headingLabel.text = L10n.accessibilityMoreActions.localizedUppercase
        }
    }

    @IBOutlet var dragHandle: ThemeableView! {
        didSet {
            dragHandle.style = .playerContrast02
        }
    }

    @IBOutlet var rearrangeHeader: ThemeableLabel! {
        didSet {
            rearrangeHeader.style = .playerContrast01
            rearrangeHeader.text = L10n.playerActionsRearrangeTitle.localizedCapitalized
        }
    }

    @IBOutlet var actionButton: ThemeableUIButton! {
        didSet {
            actionButton.style = .playerContrast01
        }
    }

    @IBOutlet var editButtonVerticalConstraint: NSLayoutConstraint!
    @IBOutlet var doneButtonVerticalConstraint: NSLayoutConstraint!

    var allActions = Settings.playerActions()
    var extraActions = Settings.playerActions()

    weak var playerActionsDelegate: NowPlayingActionsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        Analytics.track(.playerShelfOverflowMenuShown)

        reloadActions()
        updateColors()

        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateColors), name: Constants.Notifications.themeChanged, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        highlightAddBookmarksIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setPreferredSize(animated: false)
    }

    @objc func appDidBecomeActive() {
        actionsTable.reloadData()
    }

    @IBAction func doneTapped(_ sender: UIButton) {
        if actionsTable.isEditing {
            Analytics.track(.playerShelfOverflowMenuRearrangeFinished)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.playerActionsUpdated)
            dismiss(animated: true, completion: nil)
            return
        }

        actionsTable.isEditing = true
        actionsTable.reloadData()
        actionsTable.isScrollEnabled = true

        sender.setTitle(L10n.done, for: .normal)

        rearrangeHeader.isHidden = false
        dragHandle.isHidden = true
        headingLabel.isHidden = true

        headingViewHeightConstraint.constant = 56
        editButtonVerticalConstraint.isActive = false
        doneButtonVerticalConstraint.isActive = true
        setPreferredSize(animated: true)
        if let sheetController = parent as? MDCBottomSheetController {
            sheetController.dismissOnDraggingDownSheet = false
        }

        Analytics.track(.playerShelfOverflowMenuRearrangeStarted)
    }

    private func setPreferredSize(animated: Bool) {
        let newSize: CGSize
        if actionsTable.isEditing {
            newSize = view.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        } else {
            let baseSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            let adjustedSize = CGSize(width: baseSize.width, height: baseSize.height + CGFloat(extraActions.count * 72))
            newSize = adjustedSize
        }

        if animated {
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) {
                self.preferredContentSize = newSize
            }
        } else {
            preferredContentSize = newSize
        }
    }

    private func reloadActions() {
        allActions = Settings.playerActions()
        updateAvailableActions()

        actionsTable.reloadData()
    }

    @objc private func updateColors() {
        view.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
        actionsTable.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
        headingView.backgroundColor = PlayerColorHelper.playerBackgroundColor02()
        actionsTable.reloadData()
    }

    func updateAvailableActions() {
        guard let episode = PlaybackManager.shared.currentEpisode() else { return }

        let availableActions = allActions.filter { $0.canBePerformedOn(episode: episode) }
        let slice = availableActions[Constants.Limits.maxShelfActions ..< availableActions.count]
        extraActions = Array(slice)
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}

private extension ShelfActionsViewController {
    /// Highlights the bookmarks row when triggered from the what's new
    func highlightAddBookmarksIfNeeded() {
        guard FeatureFlag.bookmarks.enabled, AnnouncementFlow.shared.bookmarksFlow == .player else {
            return
        }

        defer { AnnouncementFlow.shared.bookmarksFlow = .none }

        // Find the index of the row
        guard let index = extraActions.firstIndex(of: .addBookmark) else {
            return
        }

        actionsTable.selectRow(at: .init(row: index, section: 0), animated: true, scrollPosition: .middle)
    }
}
