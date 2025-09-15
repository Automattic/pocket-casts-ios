
import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class FilterEditOptionsViewController: PCViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    var filterToEdit: EpisodeFilter!
    @IBOutlet var tableView: UITableView! {
        didSet {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Constants.Values.miniPlayerOffset, right: 0)
        }
    }

    private let nameCellId = "EditFilterNameId"
    private let iconChooserCellId = "IconChooserCellId"
    private let colorChooserCellId = "ColorChooserCell"
    private let switchCellId = "SwitchCell"
    private let disclosureCellId = "DisclosureCell"
    private let buttonCellId = "ButtonCell"
    private let settingsCellId = "SettingsCell"
    private enum TableRow: Int { case filterName, color, icon, autodownload, autoDownloadLimit, siriShortcut }
    private static let playlistRebrandingIsEnabled = FeatureFlag.playlistsRebranding.enabled
    private static let tableDataAutoDownloadDisabled: [[TableRow]] = {
        if playlistRebrandingIsEnabled {
            return [[.filterName], [.autodownload]]
        }
        return [[.filterName], [.color, .icon], [.autodownload]]
    }()
    private static let tableDataAutoDownloadEnabled: [[TableRow]] = {
        if playlistRebrandingIsEnabled {
            return [[.filterName], [.autodownload, .autoDownloadLimit]]
        }
        return [[.filterName], [.color, .icon], [.autodownload, .autoDownloadLimit]]
    }()
    private var filterNameTextField: UITextField!
    private var existingShortcut: Any!

    /* Analytics Helpers */
    private var didChangeColor = false
    private var didChangeIcon = false
    private var didChangeAutoDownload = false
    private var didChangeEpisodeCount = false
    private var isViewingShortcuts = false

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.filterOptions

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        tapRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapRecognizer)

        tableView.register(UINib(nibName: "EditFilterNameCell", bundle: nil), forCellReuseIdentifier: nameCellId)
        tableView.register(UINib(nibName: "PlaylistIconChooserCell", bundle: nil), forCellReuseIdentifier: iconChooserCellId)
        tableView.register(UINib(nibName: "PlaylistColorChooserCell", bundle: nil), forCellReuseIdentifier: colorChooserCellId)
        tableView.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: switchCellId)
        tableView.register(UINib(nibName: "DisclosureCell", bundle: nil), forCellReuseIdentifier: disclosureCellId)
        tableView.register(UINib(nibName: "ButtonCell", bundle: nil), forCellReuseIdentifier: buttonCellId)
        tableView.register(UINib(nibName: "TopLevelSettingsCell", bundle: nil), forCellReuseIdentifier: settingsCellId)
        NotificationCenter.default.addObserver(self, selector: #selector(colorChanged), name: Constants.Notifications.playlistTempChange, object: nil)

        updateExistingSortcutData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        let didChangeName = filterToEdit.playlistName != filterNameTextField.text

        filterToEdit.setTitle(filterNameTextField.text, defaultTitle: L10n.filtersDefaultNewFilter.localizedCapitalized)
        filterToEdit.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(playlist: filterToEdit)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: filterToEdit)

        if isViewingShortcuts == false {
            Analytics.track(.filterEditDismissed, properties: ["did_change_name": didChangeName,
                                                               "did_change_color": didChangeColor,
                                                               "did_change_icon": didChangeIcon,
                                                               "did_change_auto_download": didChangeAutoDownload,
                                                               "did_change_episode_count": didChangeEpisodeCount])
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        isViewingShortcuts = false
    }

    @objc func backgroundTapped(_ sender: UITapGestureRecognizer) {
        if let nameTextField = filterNameTextField {
            if nameTextField.isFirstResponder {
                nameTextField.resignFirstResponder()
            }
        }
    }

    // MARL:- TableView Data Source
    func numberOfSections(in tableView: UITableView) -> Int {
        tableData().count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData()[section].count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 1 ? 79 : 64
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableRow = tableData()[indexPath.section][indexPath.row]
        switch tableRow {
        case .filterName:
            let cell = tableView.dequeueReusableCell(withIdentifier: nameCellId) as! EditFilterNameCell
            cell.nameTextField.text = filterToEdit.playlistName
            filterNameTextField = cell.nameTextField
            cell.nameTextField.delegate = self
            return cell
        case .color:
            let cell = tableView.dequeueReusableCell(withIdentifier: colorChooserCellId) as! PlaylistColorChooserCell
            cell.playlist = filterToEdit
            return cell
        case .icon:
            let cell = tableView.dequeueReusableCell(withIdentifier: iconChooserCellId) as! PlaylistIconChooserCell
            cell.filterToEdit = filterToEdit
            cell.setupWithTintColor(tintColor: filterToEdit.playlistColor(), selectedIcon: filterToEdit.customIcon, selectHandler: { selectedIcon in
                self.didChangeIcon = true
                self.filterToEdit.customIcon = selectedIcon
                tableView.reloadData()
            })
            return cell

        case .autodownload:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId) as! SwitchCell
            cell.cellSwitch.onStyle = Self.playlistRebrandingIsEnabled ? .primaryIcon01 : filterToEdit.playlistStyle()

            cell.cellLabel.text = L10n.settingsAutoDownload
            cell.cellLabel.font.withSize(16)
            cell.setImage(imageName: "filter_downloaded")
            cell.cellSwitch.setOn(filterToEdit.autoDownloadEpisodes, animated: true)

            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            return cell
        case .autoDownloadLimit:
            let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCellId) as! DisclosureCell
            cell.cellLabel.text = L10n.autoDownloadPromptFirst
            cell.cellSecondaryLabel.text = L10n.episodeCountPluralFormat(filterToEdit.maxAutoDownloadEpisodes().localized())

            return cell
        case .siriShortcut:
            let cell = tableView.dequeueReusableCell(withIdentifier: settingsCellId) as! TopLevelSettingsCell
            cell.settingsLabel.text = L10n.settingsSiriShortcuts
            cell.settingsImage.image = UIImage(named: "settings_shortcuts")
            cell.settingsImage.tintColor = Self.playlistRebrandingIsEnabled ? AppTheme.colorForStyle(.primaryIcon01) : filterToEdit.playlistColor()
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tableRow = tableData()[indexPath.section][indexPath.row]

        switch tableRow {
        case .autoDownloadLimit:

            tableView.deselectRow(at: indexPath, animated: true)

            let options = OptionsPicker(title: L10n.autoDownloadFirst)
            let currentLimit = filterToEdit.maxAutoDownloadEpisodes()
            addAutoLimitOption(optionPicker: options, limit: 5, currentLimit: currentLimit)
            addAutoLimitOption(optionPicker: options, limit: 10, currentLimit: currentLimit)
            addAutoLimitOption(optionPicker: options, limit: 20, currentLimit: currentLimit)
            addAutoLimitOption(optionPicker: options, limit: 40, currentLimit: currentLimit)
            addAutoLimitOption(optionPicker: options, limit: 100, currentLimit: currentLimit)

            options.show(statusBarStyle: preferredStatusBarStyle)
        case .siriShortcut:
            isViewingShortcuts = true
            let singleFilterVC = FilterShortcutsViewController(filter: filterToEdit)
            navigationController?.pushViewController(singleFilterVC, animated: true)
            tableView.deselectRow(at: indexPath, animated: false)
        default:
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let autoDownloadSection = Self.playlistRebrandingIsEnabled ? 1 : 2
        if section == autoDownloadSection {
            return filterToEdit.autoDownloadEpisodes ? L10n.episodeCountPluralFormat(filterToEdit.maxAutoDownloadEpisodes().localized()) : L10n.autoDownloadOffSubtitle
        }
        return nil
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }

    // MARK: Actions

    @objc private func colorChanged() {
        didChangeColor = true
        tableView.reloadData()
    }

    @objc private func switchChanged(_ sender: UISwitch) {
        Analytics.track(.filterAutoDownloadUpdated, properties: ["enabled": sender.isOn, "source": AnalyticsSource.filters])
        filterToEdit.autoDownloadEpisodes = sender.isOn
        didChangeAutoDownload = true
        tableView.reloadData()
    }

    // MARK: - TextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidStart)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidEnd)
        filterToEdit.setTitle(filterNameTextField.text, defaultTitle: L10n.filtersDefaultNewFilter.localizedCapitalized)
        textField.resignFirstResponder()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        true
    }

    // MARK: - Theme changes

    override func handleThemeChanged() {
        tableView.reloadData()
    }

    // MARK: - Table Data

    private func tableData() -> [[FilterEditOptionsViewController.TableRow]] {
        var data = filterToEdit.autoDownloadEpisodes ? FilterEditOptionsViewController.tableDataAutoDownloadEnabled : FilterEditOptionsViewController.tableDataAutoDownloadDisabled

        data.append([.siriShortcut])

        return data
    }

    // MARK: - Private Helper Methods

    private func addAutoLimitOption(optionPicker: OptionsPicker, limit: Int32, currentLimit: Int32) {
        let action = OptionAction(label: L10n.episodeCountPluralFormat(limit.localized()), selected: currentLimit == limit) { [weak self] in
            Analytics.track(.filterAutoDownloadLimitUpdated, properties: ["limit": limit])
            self?.didChangeEpisodeCount = true
            self?.filterToEdit.autoDownloadLimit = limit
            self?.tableView.reloadData()
        }
        optionPicker.addAction(action: action)
    }

    private func updateExistingSortcutData() {
        SiriShortcutsManager.shared.voiceShortcutForFilter(filter: filterToEdit, completion: { voiceShortcut in
            self.existingShortcut = voiceShortcut
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }
}
