import PocketCastsServer
import UIKit

class AppearanceViewController: SimpleNotificationsViewController, UITableViewDataSource, UITableViewDelegate, IconSelectorCellDelegate {
    private let switchCellId = "SwitchCell"
    private let disclosureCellId = "DisclosureCell"
    private let buttonCellId = "ButtonCell"
    private let themeSelectorCellId = "ThemeSelectorCell"
    private let iconSelectorCellId = "IconSelectorCell"
    private let plusLockedInfoCellId = "PlusLockedCell"

    private enum TableRow {
        case themeOption, lightTheme, darkTheme, appIcon, refreshArtwork, embeddedArtwork, plusCallout, darkUpNextTheme
    }

    private var tableData = [[TableRow]]()

    @IBOutlet var settingsTable: UITableView! {
        didSet {
            settingsTable.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: switchCellId)
            settingsTable.register(UINib(nibName: "DisclosureCell", bundle: nil), forCellReuseIdentifier: disclosureCellId)
            settingsTable.register(UINib(nibName: "ButtonCell", bundle: nil), forCellReuseIdentifier: buttonCellId)
            settingsTable.register(UINib(nibName: "IconSelectorCell", bundle: nil), forCellReuseIdentifier: iconSelectorCellId)
            settingsTable.register(UINib(nibName: "PlusLockedInfoCell", bundle: nil), forCellReuseIdentifier: plusLockedInfoCellId)
            settingsTable.applyInsetForMiniPlayer()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsAppearance
        updateTableAndData()
        addCustomObserver(ServerNotifications.subscriptionStatusChanged, selector: #selector(subscriptionStatusChanged))

        Analytics.track(.settingsAppearanceShown)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        if let appSection = tableData.firstIndex(of: [.appIcon]), let iconSelectorCell = settingsTable.cellForRow(at: IndexPath(item: 0, section: appSection)) as? IconSelectorCell {
            iconSelectorCell.scrollToSelected()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: Constants.Notifications.themeChanged, object: nil)
    }

    deinit {
        removeAllCustomObservers()
    }

    @objc func subscriptionStatusChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.updateTableAndData()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    @objc private func themeDidChange() {
        updateTableAndData()
    }

    // MARK: - UITableView Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        tableData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData[safe: section]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowType = tableData[indexPath.section][indexPath.row]

        if rowType == .appIcon {
            return 188
        } else if rowType == .plusCallout {
            return 161
        }

        return 44
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType = tableData[indexPath.section][indexPath.row]
        switch rowType {
        case .themeOption:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = L10n.appearanceMatchDeviceTheme
            cell.cellSwitch.accessibilityIdentifier = "system theme toggle"
            cell.cellSwitch.isOn = Settings.shouldFollowSystemTheme()

            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(shouldFollowSystemThemeToggled(_:)), for: UIControl.Event.valueChanged)

            return cell

        case .darkUpNextTheme:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = L10n.settingsUpNextDarkModeTitle
            cell.cellSwitch.isOn = Settings.darkUpNextTheme
            cell.cellSwitch.removeTarget(self, action: nil, for: .valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(darkUpNextToggled(_:)), for: .valueChanged)

            return cell

        case .lightTheme:
            let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = Settings.shouldFollowSystemTheme() ? L10n.appearanceLightTheme : L10n.appearanceThemeHeader
            cell.cellSecondaryLabel.text = Theme.preferredLightTheme().description

            return cell
        case .darkTheme:
            let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.appearanceDarkTheme
            cell.cellSecondaryLabel.text = Theme.preferredDarkTheme().description

            return cell
        case .appIcon:
            let cell = tableView.dequeueReusableCell(withIdentifier: iconSelectorCellId, for: indexPath) as! IconSelectorCell
            cell.delegate = self
            cell.isAccessibilityElement = false
            cell.collectionView.isAccessibilityElement = false
            return cell
        case .refreshArtwork:
            let cell = tableView.dequeueReusableCell(withIdentifier: buttonCellId, for: indexPath) as! ButtonCell
            cell.buttonTitle.text = L10n.appearanceRefreshAllArtwork

            return cell
        case .embeddedArtwork:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = L10n.appearanceEmbeddedArtwork
            cell.cellSwitch.isOn = Settings.loadEmbeddedImages

            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(loadEmbeddedArtToggled(_:)), for: UIControl.Event.valueChanged)

            return cell
        case .plusCallout:
            let cell = tableView.dequeueReusableCell(withIdentifier: plusLockedInfoCellId, for: indexPath) as! PlusLockedInfoCell
            cell.lockView.delegate = self
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = tableData[indexPath.section][indexPath.row]

        if row == .refreshArtwork {
            SJUIUtils.showAlert(title: L10n.appearanceRefreshAllArtworkConfTitle, message: L10n.appearanceRefreshAllArtworkConfMsg, from: self)
            refreshAllPodcastArtwork()
        } else if row == .lightTheme {
            presentThemePicker(selectedTheme: Theme.preferredLightTheme()) { [weak self] theme in
                Theme.setPreferredLightTheme(theme, systemIsDark: self?.traitCollection.userInterfaceStyle == .dark)
            }
        } else if row == .darkTheme {
            presentThemePicker(selectedTheme: Theme.preferredDarkTheme()) { [weak self] theme in
                Theme.setPreferredDarkTheme(theme, systemIsDark: self?.traitCollection.userInterfaceStyle == .dark, userInitiated: true)
            }
        }
    }

    private func presentThemePicker(selectedTheme: Theme.ThemeType, persistThemeChange: @escaping (Theme.ThemeType) -> Void) {
        let themeSelector = ThemeSelectorView(title: L10n.appearanceThemeSelect, onThemeSelected: { [weak self] theme in
            guard let self = self else { return }

            if theme.isPlusOnly, !SubscriptionHelper.hasActiveSubscription() {
                self.dismiss(animated: true) {
                    NavigationManager.sharedManager.showUpsellView(from: self, source: .themes)
                }

                return
            }

            persistThemeChange(theme)
            self.updateTableAndData()
            self.dismiss(animated: true, completion: nil)
        }, dismissAction: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }, selectedTheme: selectedTheme).environmentObject(Theme.sharedTheme)
        let hostingController = PCHostingController(rootView: themeSelector)

        present(hostingController, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerFrame = CGRect(x: 0, y: 0, width: 0, height: Constants.Values.tableSectionHeaderHeight)

        switch tableData[section][0] {
        case .themeOption:
            return SettingsTableHeader(frame: headerFrame, title: L10n.appearanceThemeHeader)
        case .appIcon:
            return SettingsTableHeader(frame: headerFrame, title: L10n.appearanceAppIconHeader)
        case .refreshArtwork:
            return SettingsTableHeader(frame: headerFrame, title: L10n.appearanceArtworkHeader)
        case .darkUpNextTheme:
            return SettingsTableHeader(frame: headerFrame, title: L10n.upNext)
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Constants.Values.tableSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch tableData[section][0] {
        case .refreshArtwork:
            L10n.appearanceEmbeddedArtworkSubtitle
        case .darkUpNextTheme:
            L10n.settingsUpNextDarkModeFooter
        default: nil
        }
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let item = tableData[indexPath.section][indexPath.row]

        return item == .plusCallout ? nil : indexPath
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    // MARK: - Actions
    @objc private func darkUpNextToggled(_ sender: UISwitch) {
        Settings.darkUpNextTheme = sender.isOn
        Settings.trackValueToggled(.settingsAppearanceUseDarkUpNextToggled, enabled: sender.isOn)
    }

    @objc private func shouldFollowSystemThemeToggled(_ sender: UISwitch) {
        Settings.setShouldFollowSystemTheme(sender.isOn)
        updateTableAndData()

        if sender.isOn {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.followSystemThemeTurnedOn)
        } else if Theme.sharedTheme.activeTheme != Theme.preferredLightTheme() {
            Theme.sharedTheme.activeTheme = Theme.preferredLightTheme()
        }

        Settings.trackValueToggled(.settingsAppearanceFollowSystemThemeToggled, enabled: sender.isOn)
    }

    @objc private func loadEmbeddedArtToggled(_ sender: UISwitch) {
        Settings.loadEmbeddedImages = sender.isOn
    }

    private func updateTableAndData() {
        var newTableData: [[TableRow]]
        if Settings.shouldFollowSystemTheme() {
            newTableData = [[.themeOption, .lightTheme, .darkTheme], [.appIcon], [.refreshArtwork, .embeddedArtwork], [.darkUpNextTheme]]
        } else {
            newTableData = [[.themeOption, .lightTheme], [.appIcon], [.refreshArtwork, .embeddedArtwork], [.darkUpNextTheme]]
        }

        if !SubscriptionHelper.hasActiveSubscription(), !Settings.plusInfoDismissedOnAppearance() {
            newTableData.append([.plusCallout])
        }

        tableData = newTableData
        settingsTable.reloadData()
    }

    private func refreshAllPodcastArtwork() {
        DispatchQueue.global(qos: .default).async { () in
            ImageManager.sharedManager.clearPodcastCache(recacheWhenDone: true)
        }

        Analytics.track(.settingsAppearanceRefreshAllArtworkTapped)
    }

    // MARK: - IconSelectorCellDelegate

    func changeIcon(icon: IconType) {
        let name = icon.iconName

        AnalyticsHelper.didChooseIcon(iconName: name)
        UIApplication.shared.setAlternateIconName(name, completionHandler: { _ in
            WidgetHelper.shared.updateWidgetAppIcon()
            DispatchQueue.main.async {
                self.updateTableAndData()
            }
        })

        Settings.trackValueChanged(.settingsAppearanceAppIconChanged, value: icon)
    }

    func iconSelectorPresentingVC() -> UIViewController {
        self
    }
}

// MARK: - PlusLockedInfoDelegate

extension AppearanceViewController: PlusLockedInfoDelegate {
    func closeInfoTapped() {
        Settings.setPlusInfoDismissedOnAppearance(true)
        updateTableAndData()
    }

    var displayingViewController: UIViewController {
        self
    }

    var displaySource: PlusUpgradeViewSource {
        .appearance
    }
}
