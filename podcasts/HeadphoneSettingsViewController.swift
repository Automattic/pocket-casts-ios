import Combine
import UIKit

class HeadphoneSettingsViewController: PCTableViewController {
    private var allSections: [TableSection] = [
        .init(rows: [.previousAction, .nextAction], footer: L10n.settingsHeadphoneControlsFooter),
        .init(rows: [.bookmarkSound], footer: L10n.settingsBookmarkSoundFooter)
    ]

    private var visibleSections: [TableSection] = []
    private let bookmarksManager = BookmarkManager()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsHeadphoneControls
        Analytics.track(.settingsHeadphoneControlsShown)
    }

    override var customCellTypes: [ReusableTableCell.Type] {
        [SwitchCell.self, DisclosureCell.self]
    }

    override func reloadData() {
        visibleSections = allSections.filter(\.visible)

        super.reloadData()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let section = visibleSections[indexPath.section]
        let row = section.rows[indexPath.row]

        let actions: [HeadphoneControlAction] = [.skipForward, .nextChapter, .skipBack, .previousChapter, .addBookmark]

        switch row {
        case .nextAction:
            showPicker(L10n.settingsNextAction, actions, currentValue: Settings.headphonesNextAction) { [weak self] in
                self?.headphoneOptionChanged(to: $0, for: row)
            }
        case .previousAction:
            showPicker(L10n.settingsPreviousAction, actions, currentValue: Settings.headphonesPreviousAction) { [weak self] in
                self?.headphoneOptionChanged(to: $0, for: row)
            }
        case .bookmarkSound:
            // Toggle the value when the row is tapped
            let enabled = !Settings.playBookmarkCreationSound
            updateBookmarkSoundEnabled(enabled)

            // Change the switch state
            if let cell = tableView.cellForRow(at: indexPath) as? SwitchCell {
                cell.cellSwitch.setOn(enabled, animated: true)
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = visibleSections[indexPath.section]
        let row = section.rows[indexPath.row]

        switch row {
        case .previousAction:
            let cell = tableView.dequeueReusableCell(DisclosureCell.self, for: indexPath)
            cell.cellLabel.text = L10n.settingsPreviousAction
            cell.setImage(imageName: "settings_headphone_controls_skip_back")
            cell.cellSecondaryLabel.text = Settings.headphonesPreviousAction.displayableTitle

            return cell
        case .nextAction:
            let cell = tableView.dequeueReusableCell(DisclosureCell.self, for: indexPath)
            cell.cellLabel.text = L10n.settingsNextAction
            cell.setImage(imageName: "settings_headphone_controls_skip_forward")
            cell.cellSecondaryLabel.text = Settings.headphonesNextAction.displayableTitle
            return cell

        case .bookmarkSound:
            let cell = tableView.dequeueReusableCell(SwitchCell.self, for: indexPath)
            cell.cellLabel.text = L10n.settingsBookmarkConfirmationSound
            cell.cellSwitch.isOn = Settings.playBookmarkCreationSound

            cell.cellSwitch.removeTarget(self, action: nil, for: .valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(bookmarkSoundToggled(_:)), for: .valueChanged)
            return cell
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        visibleSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleSections[section].rows.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Constants.rowHeight
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        visibleSections[section].footer
    }

    // MARK: - Bookmark Sound

    @objc func bookmarkSoundToggled(_ sender: UISwitch) {
        updateBookmarkSoundEnabled(sender.isOn)
    }

    private func updateBookmarkSoundEnabled(_ enabled: Bool) {
        Settings.playBookmarkCreationSound = enabled
        Settings.trackValueToggled(.settingsHeadphoneControlsBookmarkSoundToggled, enabled: enabled)

        // Play a preview of the sound if the user has enabled the option
        if enabled {
            bookmarksManager.playTone()
        }
    }

    // MARK: - Headphone Option

    private func headphoneOptionChanged(to selection: HeadphoneControlAction, for row: TableSection.Row) {
        // Store the setting action as a closure to be able to finish setting the value after the purchase
        let action = { [weak self] in
            switch row {
            case .previousAction:
                Settings.trackValueChanged(.settingsHeadphoneControlsPreviousChanged, value: selection)
                Settings.headphonesPreviousAction = selection

            case .nextAction:
                Settings.trackValueChanged(.settingsHeadphoneControlsNextChanged, value: selection)
                Settings.headphonesNextAction = selection

            default: break
            }

            self?.reloadData()
        }

        // Show the upsell if needed
        selection.isUnlocked ? action() : showUpsell(for: selection, unlocked: action)
    }

    private func showUpsell(for selection: HeadphoneControlAction, unlocked: @escaping () -> Void) {
        guard let feature = selection.paidFeature else { return }

        // If the feature is unlocked, then finish updating the setting they were trying to change to
        // This will only fire once, and only if the feature is unlocked.
        feature.objectWillChange
            .receive(on: DispatchQueue.main)
            .filter { feature.isUnlocked }
            .first()
            .sink { unlocked() }
            .store(in: &cancellables)

        feature.presentUpgradeController(from: self, source: "headphone_settings")
    }

    // MARK: - Data Struct

    private struct TableSection {
        /// The visible rows in the section
        var rows: [Row] {
            allRows.filter(\.visible)
        }

        /// Whether the section should be visible or not
        var visible: Bool {
            !rows.isEmpty
        }

        private let allRows: [Row]

        /// The footer text to display
        let footer: String

        init(rows: [Row], footer: String) {
            self.allRows = rows
            self.footer = footer
        }

        enum Row {
            case previousAction, nextAction
            case bookmarkSound

            var visible: Bool {
                switch self {
                case .bookmarkSound:
                    // Only show this option if the user has selected addBookmark as one of the options
                    return  Settings.isPlayBookmarkCreationSoundAvailable
                default:
                    return true
                }
            }
        }
    }

    private enum Constants {
        static let rowHeight = 56.0
    }
}

// MARK: - Private: Options Picker

private extension HeadphoneSettingsViewController {
    private func showPicker(_ title: String, _ options: [HeadphoneControlAction], currentValue: HeadphoneControlAction, onChange: @escaping ((HeadphoneControlAction) -> Void)) {
        let picker = OptionsPicker(title: title)
        picker.addActions(options.map { option in
            OptionAction(label: option.displayableTitle, icon: option.iconName, tintIcon: false, selected: currentValue == option) {
                onChange(option)
            }
        })
        picker.show(statusBarStyle: preferredStatusBarStyle)
    }
}

// MARK: - Helper extension to get the title and image for each option

private extension HeadphoneControlAction {
    var displayableTitle: String {
        switch self {
        case .skipBack:
            return L10n.skipBack
        case .skipForward:
            return L10n.skipForward
        case .previousChapter:
            return L10n.siriShortcutPreviousChapter.localizedCapitalized
        case .nextChapter:
            return L10n.siriShortcutNextChapter.localizedCapitalized
        case .addBookmark:
            return L10n.addBookmark
        }
    }

    var iconName: String? {
        isUnlocked ? nil : "plusGold24"
    }
}
