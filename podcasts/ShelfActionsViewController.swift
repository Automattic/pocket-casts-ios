import UIKit

class ShelfActionsViewController: UIViewController, CheckTranscriptAvailability {
    @IBOutlet var actionsTable: UITableView! {
        didSet {
            registerCells()
            actionsTable.isScrollEnabled = true
            actionsTable.backgroundView = nil

            actionsTable.separatorColor = AppTheme.tableDividerColor(for: .dark)
            actionsTable.indicatorStyle = AppTheme.indicatorStyle()

            actionsTable.rowHeight = UITableView.automaticDimension
            actionsTable.sectionHeaderHeight = UITableView.automaticDimension
        }
    }

    @IBOutlet var headingView: UIView!
    @IBOutlet var headingViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var headingLabel: ThemeableLabel! {
        didSet {
            headingLabel.style = .playerContrast02
            headingLabel.text = L10n.accessibilityMoreActions.localizedUppercase
            headingLabel.font = UIFont.font(ofSize: 13, weight: .medium, scalingWith: .title1)
            headingLabel.adjustsFontForContentSizeCategory = true
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
            rearrangeHeader.font = UIFont.font(ofSize: 13, weight: .medium, scalingWith: .title1)
            rearrangeHeader.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var actionButton: ThemeableUIButton! {
        didSet {
            actionButton.style = .playerContrast01
            actionButton.titleLabel?.font = UIFont.font(ofSize: 17, weight: .semibold, scalingWith: .title1)
            actionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var editButtonVerticalConstraint: NSLayoutConstraint!
    @IBOutlet var doneButtonVerticalConstraint: NSLayoutConstraint!

    var allActions = Settings.playerActions()
    var extraActions = Settings.playerActions()
    var maxShelfActionsAdjustment: Int = 0

    weak var playerActionsDelegate: NowPlayingActionsDelegate?

    private var sheetPresentationDismissalBlocker: ShelfActionsSheetDismissalBlocker?

    var hasGeneratedTranscripts = false
    var isTranscriptEnabled = false {
        didSet {
            reloadActions()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Analytics.track(.playerShelfOverflowMenuShown)

        reloadActions()
        updateColors()

        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateColors), name: Constants.Notifications.themeChanged, object: nil)

        addTranscriptObservers()
        checkTranscriptAvailability()
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
        setPreferredSize(animated: true)

        if let sheetController = sheetPresentationController {
            // If we're being presented in a bottom sheet enlarge it to (almost) fill the
            // screen and drop any other detents so the sheet cannot be made smaller by
            // the user.
            sheetController.animateChanges { sheetController.detents = [.large()] }

            // Prevent the user from swiping to dismiss the bottom sheet.
            sheetPresentationDismissalBlocker = .init()
            sheetController.delegate = sheetPresentationDismissalBlocker
        }

        Analytics.track(.playerShelfOverflowMenuRearrangeStarted)
    }

    /// Whether the controller is shown in an actual popover rather than adapted to a sheet.
    private var isShownInPopover: Bool {
        popoverPresentationController != nil && sheetPresentationController == nil
    }

    func presentAsPopover(from sourceView: UIView, in presenter: UIViewController) {
        modalPresentationStyle = .popover
        if let popover = popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
            popover.permittedArrowDirections = [.up, .down]
            popover.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
            popover.delegate = self
        }
        presenter.present(self, animated: true)
    }

    private func setPreferredSize(animated: Bool) {
        let newSize: CGSize
        if isShownInPopover {
            newSize = popoverContentSize()
        } else if actionsTable.isEditing {
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

    private func popoverContentSize() -> CGSize {
        let width: CGFloat = 400
        dragHandle.isHidden = true
        view.frame.size.width = width
        view.layoutIfNeeded()
        actionsTable.layoutIfNeeded()
        actionsTable.contentInsetAdjustmentBehavior = .never
        let lastSection = actionsTable.numberOfSections - 1
        let lastRow = actionsTable.numberOfRows(inSection: lastSection) - 1
        let contentHeight = lastRow >= 0 ? actionsTable.rectForRow(at: IndexPath(row: lastRow, section: lastSection)).maxY : actionsTable.contentSize.height
        let height = headingView.bounds.height + contentHeight
        return CGSize(width: width, height: height)
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

    @objc private func episodeTranscriptAvailabilityChanged(notification: NSNotification) {
        guard let episodeUuid = notification.userInfo?["episodeUuid"] as? String,
              notification.userInfo?["isAvailable"] as? Bool != nil,
              episodeUuid == PlaybackManager.shared.currentEpisode?.uuid else {
            return
        }
    }

    func updateAvailableActions() {
        guard let episode = PlaybackManager.shared.currentEpisode else { return }

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
        guard AnnouncementFlow.current == .bookmarksPlayer else {
            return
        }

        defer { AnnouncementFlow.current = .none }

        // Find the index of the row
        guard let index = extraActions.firstIndex(of: .addBookmark) else {
            return
        }

        actionsTable.selectRow(at: .init(row: index, section: 0), animated: true, scrollPosition: .middle)
    }
}

extension ShelfActionsViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        .pageSheet
    }

    func presentationController(_ presentationController: UIPresentationController, prepare adaptivePresentationController: UIPresentationController) {
        guard let sheet = adaptivePresentationController as? UISheetPresentationController else { return }
        let height = view.sizeThatFits(CGSize(width: view.bounds.width, height: .greatestFiniteMagnitude)).height
        sheet.detents = [.custom(resolver: { _ in height })]
        sheet.prefersGrabberVisible = false
    }
}

/// A UISheetPresentationControllerDelegate that prevents the user from swiping the
/// sheet away by always rejecting dismissal requests. Programmatic dismissals are still
/// respected.
private final class ShelfActionsSheetDismissalBlocker: NSObject, UISheetPresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        false
    }
}
