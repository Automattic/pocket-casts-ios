import UIKit

class HeadphoneSettingsViewController: PCTableViewController {
    private var allSections: [TableSection] = [
        .init(rows: [.previousAction, .nextAction], footer: L10n.settingsHeadphoneControlsFooter),
        .init(rows: [.bookmarkSound], footer: L10n.settingsBookmarkSoundFooter)
    ]

    private var visibleSections: [TableSection] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsHeadphoneControls
    }

    override var customCellTypes: [ReusableTableCell.Type] {
        [SwitchCell.self, DisclosureCell.self]
    }

    override func reloadData() {
        visibleSections = allSections.filter(\.visible)

        super.reloadData()
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
                    let optionEnabled = [Settings.headphonesNextAction, Settings.headphonesPreviousAction].contains(.addBookmark)
                    // and the FeatureFlag is enabled
                    return FeatureFlag.bookmarks.enabled && optionEnabled
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
            OptionAction(label: option.displayableTitle, icon: option.iconName, selected: currentValue == option) {
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
        switch self {
        case .addBookmark:
            return "plusGold"
        default:
            return nil
        }
    }
}
