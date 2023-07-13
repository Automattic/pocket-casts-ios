import MaterialComponents.MaterialBottomSheet
import PocketCastsDataModel
import UIKit

protocol MultiSelectActionOrderDelegate {
    func actionOrderChanged()
}

class MultiSelectActionController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let actionCellId = "MultiSelectCellId"

    private let shortcutSection = 0
    private let inMenuSection = 1

    @IBOutlet var headerView: ThemeableView! {
        didSet {
            headerView.themeOverride = themeOverride
        }
    }

    @IBOutlet var dragHandle: ThemeableView! {
        didSet {
            dragHandle.style = .primaryUi05
            dragHandle.layer.cornerRadius = 2
            dragHandle.themeOverride = themeOverride
        }
    }

    @IBOutlet var selectedCountLabel: ThemeableLabel! {
        didSet {
            selectedCountLabel.style = .primaryText02
            selectedCountLabel.themeOverride = themeOverride
        }
    }

    @IBOutlet var editButton: UIButton! {
        didSet {
            editButton.setTitle(L10n.edit, for: .normal)
        }
    }

    @IBOutlet var doneButton: UIButton! {
        didSet {
            doneButton.setTitle(L10n.done, for: .normal)
        }
    }

    @IBOutlet var rearrangeLabel: ThemeableLabel! {
        didSet {
            rearrangeLabel.themeOverride = themeOverride
            rearrangeLabel.text = L10n.playerActionsRearrangeTitle.localizedCapitalized
        }
    }

    @IBOutlet var actionsTable: ThemeableTable! {
        didSet {
            actionsTable.register(UINib(nibName: "MultiSelectActionCell", bundle: nil), forCellReuseIdentifier: actionCellId)
            actionsTable.themeStyle = .primaryUi01
            actionsTable.themeOverride = themeOverride
        }
    }

    private var originalActions: [MultiSelectAction]
    private var orderedActions: [MultiSelectAction]
    private var delegate: MultiSelectActionOrderDelegate
    private var actionDelegate: MultiSelectActionDelegate
    private var numSelectedEpisodes: Int
    static let numShortcuts = 2
    static let rowHeight: CGFloat = 72
    var setActionsFunc: ([MultiSelectAction]) -> Void
    private var themeOverride: Theme.ThemeType?

    init(actions: [MultiSelectAction], delegate: MultiSelectActionOrderDelegate, actionDelegate: MultiSelectActionDelegate, numSelectedEpisodes: Int, setActionsFunc: @escaping (([MultiSelectAction]) -> Void), themeOverride: Theme.ThemeType?) {
        orderedActions = actions
        originalActions = actions
        self.delegate = delegate
        self.actionDelegate = actionDelegate
        self.numSelectedEpisodes = numSelectedEpisodes
        self.setActionsFunc = setActionsFunc
        self.themeOverride = themeOverride
        super.init(nibName: "MultiSelectActionController", bundle: nil)
        filterUnavailableActions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedCountLabel.text = numSelectedEpisodes == 1 ? L10n.multiSelectSelectedCountSingular : L10n.multiSelectSelectedCountPlural(numSelectedEpisodes.localized())
        actionsTable.isScrollEnabled = false
        rearrangeLabel.isHidden = true
        doneButton.isHidden = true
        updateColors()
        setPreferredSize(animated: false)

        Analytics.track(.multiSelectViewOverflowMenuShown, properties: ["source": actionDelegate.multiSelectViewSource])
    }

    // MARK: - TableView

    func numberOfSections(in tableView: UITableView) -> Int {
        actionsTable.isEditing ? 2 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let nonShortcutActionCount = orderedActions.count - MultiSelectActionController.numShortcuts
        if section == inMenuSection {
            return nonShortcutActionCount
        }
        return actionsTable.isEditing ? MultiSelectActionController.numShortcuts : nonShortcutActionCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let action = actionAt(indexPath: indexPath, isEditing: actionsTable.isEditing)

        let cell = tableView.dequeueReusableCell(withIdentifier: actionCellId, for: indexPath) as! MultiSelectActionCell

        cell.nameLabel.text = action.title()
        cell.iconView.image = UIImage(named: action.iconName())
        cell.iconView.tintColor = AppTheme.colorForStyle(.primaryInteractive01, themeOverride: themeOverride)
        cell.style = .primaryUi01
        cell.themeOverride = themeOverride
        cell.iconStyle = .primaryIcon01
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        MultiSelectActionController.rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAction = actionAt(indexPath: indexPath, isEditing: actionsTable.isEditing)
        dismiss(animated: true, completion: nil)
        MultiSelectHelper.performAction(selectedAction, actionDelegate: actionDelegate)
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let rowsInShelfSection = tableView.numberOfRows(inSection: 0)
        let fromRow = sourceIndexPath.row + (sourceIndexPath.section * MultiSelectActionController.numShortcuts)
        let toRow = destinationIndexPath.row + (destinationIndexPath.section * rowsInShelfSection)

        let action = orderedActions.remove(at: fromRow)
        orderedActions.insert(action, at: toRow)

        let fromName = sourceIndexPath.section == 0 ? "shelf" : "overflow_menu"
        let toName = destinationIndexPath.section == 0 ? "shelf" : "overflow_menu"

        let source = actionDelegate.multiSelectViewSource
        Analytics.track(.multiSelectViewOverflowMenuRearrangeActionMoved, properties: ["source": source, "action": action, "moved_from": fromName, "moved_to": toName, "position": destinationIndexPath.row])

        // if someone has moved something into the shortcut section, move the bottom item out. Done async so that this method can return first
        if destinationIndexPath.section == shortcutSection, sourceIndexPath.section != shortcutSection {
            DispatchQueue.main.async {
                tableView.beginUpdates()
                tableView.moveRow(at: IndexPath(row: MultiSelectActionController.numShortcuts, section: self.shortcutSection), to: IndexPath(row: 0, section: self.inMenuSection))
                tableView.endUpdates()
            }
        }
        // another option is they could move something out of the shortcut section into the menu section, which also requires a re-shuffle
        else if destinationIndexPath.section == inMenuSection, sourceIndexPath.section == shortcutSection {
            DispatchQueue.main.async {
                tableView.beginUpdates()
                tableView.moveRow(at: IndexPath(row: 0, section: self.inMenuSection), to: IndexPath(row: 1, section: self.shortcutSection))
                tableView.endUpdates()
            }
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView.isEditing {
            return 40
        }
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard tableView.isEditing else { return nil }

        let headerFrame = CGRect(x: 0, y: 0, width: 0, height: Constants.Values.tableSectionHeaderHeight)
        var title = ""

        if section == shortcutSection {
            title = L10n.multiSelectShortcutInActionBar
        } else if section == inMenuSection {
            title = L10n.settingsInMenu
        }

        let headerView = SettingsTableHeader(frame: headerFrame, title: title, showLockedImage: false, themeStyle: .primaryUi01, themeOverride: themeOverride)

        return headerView
    }

    private func actionAt(indexPath: IndexPath, isEditing: Bool) -> MultiSelectAction {
        if isEditing {
            return orderedActions[indexPath.row + (indexPath.section * MultiSelectActionController.numShortcuts)]
        } else {
            let action = orderedActions[indexPath.row + MultiSelectActionController.numShortcuts]
            return MultiSelectHelper.invertActionIfRequired(action: action, actionDelegate: actionDelegate)
        }
    }

    @IBAction func editTapped(_ sender: UIButton) {
        showAllActions()

        actionsTable.isEditing = true
        actionsTable.reloadData()

        editButton.isHidden = true
        selectedCountLabel.isHidden = true
        doneButton.isHidden = false
        rearrangeLabel.isHidden = false
        dragHandle.isHidden = true

        setPreferredSize(animated: true)

        Analytics.track(.multiSelectViewOverflowMenuRearrangeStarted, properties: ["source": actionDelegate.multiSelectViewSource])
    }

    @IBAction func doneTapped(_ sender: UIButton) {
        filterUnavailableActions()
        setActionsFunc(orderedActions)
        delegate.actionOrderChanged()
        dismiss(animated: true, completion: nil)
        Analytics.track(.multiSelectViewOverflowMenuRearrangeFinished, properties: ["source": actionDelegate.multiSelectViewSource])
    }

    private func setPreferredSize(animated: Bool) {
        let newSize: CGSize
        if actionsTable.isEditing {
            newSize = view.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
            if newSize.height > UIScreen.main.bounds.height {
                actionsTable.isScrollEnabled = true
                actionsTable.bounces = false
            }
        } else {
            let baseSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            let adjustedSize = CGSize(width: baseSize.width, height: baseSize.height + (CGFloat(orderedActions.count - MultiSelectActionController.numShortcuts) * MultiSelectActionController.rowHeight))
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

    func updateColors() {
        doneButton.setTitleColor(AppTheme.colorForStyle(.primaryInteractive01, themeOverride: themeOverride), for: .normal)
        editButton.setTitleColor(AppTheme.colorForStyle(.primaryInteractive01, themeOverride: themeOverride), for: .normal)
    }

    private func filterUnavailableActions() {
        let episodes = actionDelegate.multiSelectedBaseEpisodes()
        orderedActions = orderedActions.filter { $0.isVisible(with: episodes) }
    }

    private func showAllActions() {
        orderedActions = originalActions
        let shareableEpisodesCount = actionDelegate
            .multiSelectedBaseEpisodes()
            .filter { $0 is Episode }
            .count

        // If a user already saved the actions, share will be
        // missing since was added later to the app.
        // This ensures it's displayed except for user's files.
        if !orderedActions.contains(.share) && shareableEpisodesCount > 0 {
            orderedActions.append(.share)
        }
    }
}
