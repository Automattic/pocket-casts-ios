import PocketCastsServer
import UIKit

class UploadedSettingsViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    private let switchCellId = "SwitchCell"
    private let lockInfoCellId = "LockCell"
    private enum TableSections: Int { case autoSync, autoAddToUpNext, afterPlaying, onlyOnWifi, lockedInfo }
    private enum TableRows: Int { case autoDownload, autoUpload, autoAddToUpNext, removeFileAfterPlaying, removeFromCloudAfterPlaying, onlyOnWifi, lockedInfo }

    @IBOutlet var settingsTable: UITableView! {
        didSet {
            settingsTable.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: switchCellId)
            settingsTable.register(UINib(nibName: "PlusLockedInfoCell", bundle: nil), forCellReuseIdentifier: lockInfoCellId)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.settingsFiles
        addCustomObserver(ServerNotifications.subscriptionStatusChanged, selector: #selector(subscriptionStatusChanged))
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: settingsTable)
    }

    @objc func subscriptionStatusChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.settingsTable.reloadData()
        }
    }

    private func tableSections() -> [TableSections] {
        var sections: [TableSections] = [.autoAddToUpNext, .afterPlaying, .autoSync, .onlyOnWifi]
        if !SubscriptionHelper.hasActiveSubscription(), !Settings.plusInfoDismissedOnFilesSettings() {
            sections.append(.lockedInfo)
        }

        return sections
    }

    private func tableRows() -> [[TableRows]] {
        let hasSubscription = SubscriptionHelper.hasActiveSubscription()

        var rows: [[TableRows]] = [[.autoAddToUpNext], [.removeFileAfterPlaying], [.autoUpload, .autoDownload], [.onlyOnWifi]]
        if hasSubscription {
            rows[1].append(.removeFromCloudAfterPlaying)
        }
        if !hasSubscription, !Settings.plusInfoDismissedOnFilesSettings() {
            rows.append([.lockedInfo])
        }

        return rows
    }

    // MARK: - UITableView Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        tableSections().count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableRows()[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = tableRows()[indexPath.section][indexPath.row]

        if row == .lockedInfo {
            let cell = tableView.dequeueReusableCell(withIdentifier: lockInfoCellId, for: indexPath) as! PlusLockedInfoCell
            cell.lockView.delegate = self
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
        cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)

        switch row {
        case .autoDownload:
            cell.cellLabel?.text = L10n.settingsFilesAutoDownload
            cell.cellSwitch.isOn = ServerSettings.userEpisodeAutoDownload()
            cell.cellSwitch.addTarget(self, action: #selector(autoDownloadToggled(_:)), for: .valueChanged)
            cell.isLocked = SubscriptionHelper.hasActiveSubscription()
            cell.setImage(imageName: "episode-download")
        case .autoUpload:
            cell.cellLabel?.text = L10n.settingsFilesAutoUpload
            cell.setImage(imageName: "plus_upload")
            cell.cellSwitch.isOn = Settings.userFilesAutoUpload()
            cell.cellSwitch.addTarget(self, action: #selector(autoUploadToggled(_:)), for: .valueChanged)
            cell.isLocked = SubscriptionHelper.hasActiveSubscription()
        case .autoAddToUpNext:
            cell.cellLabel?.text = L10n.settingsAutoAdd
            cell.setImage(imageName: "settings_upnext")
            cell.cellSwitch.isOn = Settings.userEpisodeAutoAddToUpNext()
            cell.cellSwitch.addTarget(self, action: #selector(autoAddToUpNextToggled(_:)), for: .valueChanged)
        case .removeFileAfterPlaying:
            cell.cellLabel?.text = L10n.settingsFilesDeleteLocalFile
            cell.setImage(imageName: "delete")
            cell.cellSwitch.isOn = Settings.userEpisodeRemoveFileAfterPlaying()
            cell.cellSwitch.addTarget(self, action: #selector(removeFileAfterPlayingToggled(_:)), for: .valueChanged)
        case .removeFromCloudAfterPlaying:
            cell.cellLabel?.text = L10n.settingsFilesDeleteCloudFile
            cell.setImage(imageName: "settings_cloud_strikethrough")
            cell.cellSwitch.isOn = Settings.userEpisodeRemoveFromCloudAfterPlaying()
            cell.cellSwitch.addTarget(self, action: #selector(removeFromCloudAfterPlayingToggled(_:)), for: .valueChanged)
        case .onlyOnWifi:
            cell.cellLabel?.text = L10n.onlyOnWifi
            cell.setNoImage()
            cell.cellSwitch.isOn = ServerSettings.userEpisodeOnlyOnWifi()
            cell.cellSwitch.addTarget(self, action: #selector(onlyOnWifiToggled(_:)), for: .valueChanged)
            cell.isLocked = SubscriptionHelper.hasActiveSubscription()
            cell.setImage(imageName: "settings_wifi")
        case .lockedInfo:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = tableSections()[indexPath.section]
        if section == .lockedInfo {
            return 161
        }
        return 56
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let section = tableSections()[section]
        switch section {
        case .autoSync:
            let syncFooter = (Settings.userFilesAutoUpload() ? L10n.settingsFilesAutoUploadSubtitleOn : L10n.settingsFilesAutoUploadSubtitleOff)
                + "\n"
                + (ServerSettings.userEpisodeAutoDownload() ? L10n.settingsFilesAutoDownloadSubtitleOn : L10n.settingsFilesAutoDownloadSubtitleOff)

            return SubscriptionHelper.hasActiveSubscription() ? syncFooter : nil
        case .autoAddToUpNext:
            return L10n.settingsFilesAddUpNextSubtitle
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let section = tableSections()[section]
        if section == .autoSync, !SubscriptionHelper.hasActiveSubscription() {
            let fadedFooter = UIView(frame: CGRect(x: 0, y: 0, width: settingsTable.bounds.width, height: 60))
            let syncLabel = ThemeableLabel()
            syncLabel.style = .primaryText02
            syncLabel.alpha = 0.7
            syncLabel.text = L10n.settingsFilesAutoUploadSubtitleOff + "\n" + L10n.settingsFilesAutoDownloadSubtitleOff
            syncLabel.numberOfLines = 0
            syncLabel.font = UIFont.systemFont(ofSize: 12)
            syncLabel.translatesAutoresizingMaskIntoConstraints = false
            fadedFooter.addSubview(syncLabel)
            NSLayoutConstraint.activate([
                syncLabel.topAnchor.constraint(equalTo: fadedFooter.topAnchor, constant: 12),
                syncLabel.leadingAnchor.constraint(equalTo: fadedFooter.leadingAnchor, constant: 16),
                syncLabel.trailingAnchor.constraint(equalTo: fadedFooter.trailingAnchor, constant: -16),
                syncLabel.bottomAnchor.constraint(equalTo: fadedFooter.bottomAnchor)
            ])

            return fadedFooter
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let section = tableSections()[section]
        if section == .autoSync, !SubscriptionHelper.hasActiveSubscription() {
            return 60
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Constants.Values.tableSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerFrame = CGRect(x: 0, y: 0, width: 0, height: Constants.Values.tableSectionHeaderHeight)
        let title: String
        let section = tableSections()[section]
        switch section {
        case .autoSync:
            title = L10n.plusFeatures
        case .afterPlaying:
            title = L10n.afterPlaying.localizedUppercase
        default:
            title = ""
        }

        let showLockIcon = (!SubscriptionHelper.hasActiveSubscription() && section == .autoSync)
        let headerView = SettingsTableHeader(frame: headerFrame, title: title, showLockedImage: showLockIcon, lockedSelector: #selector(showSubscriptionRequired), target: self)

        return headerView
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let section = tableSections()[indexPath.section]
        if section == .lockedInfo {
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = tableSections()[indexPath.section]
        if !SubscriptionHelper.hasActiveSubscription(), section == .autoSync || section == .onlyOnWifi {
            showSubscriptionRequired()
        }
    }

    @objc func showSubscriptionRequired() {
        NavigationManager.sharedManager.showUpsellView(from: self, source: .files)
    }

    // MARK: - Switch Actions

    @objc private func autoDownloadToggled(_ sender: UISwitch) {
        ServerSettings.setUserEpisodeAutoDownload(sender.isOn)
        settingsTable.reloadData()
        Settings.trackValueToggled(.settingsFilesAutoDownloadFromCloudToggled, enabled: sender.isOn)
    }

    @objc private func autoUploadToggled(_ sender: UISwitch) {
        Settings.setUserEpisodeAutoUpload(sender.isOn)
        settingsTable.reloadData()
    }

    @objc private func autoAddToUpNextToggled(_ sender: UISwitch) {
        Settings.setUserEpisodeAutoAddToUpNext(sender.isOn)
    }

    @objc private func removeFileAfterPlayingToggled(_ sender: UISwitch) {
        Settings.setUserEpisodeRemoveFileAfterPlaying(sender.isOn)
    }

    @objc private func removeFromCloudAfterPlayingToggled(_ sender: UISwitch) {
        Settings.setUserEpisodeRemoveFromCloudAfterPlayingKey(sender.isOn)
    }

    @objc private func onlyOnWifiToggled(_ sender: UISwitch) {
        ServerSettings.setUserEpisodeOnlyOnWifi(sender.isOn)
        Settings.trackValueToggled(.settingsFilesOnlyOnWifiToggled, enabled: sender.isOn)
    }
}

// MARK: - PlusLockedInfoDelegate

extension UploadedSettingsViewController: PlusLockedInfoDelegate {
    func closeInfoTapped() {
        Settings.setPlusInfoDismissedOnFilesSettings(true)
        settingsTable.reloadData()
    }

    var displayingViewController: UIViewController {
        self
    }

    var displaySource: PlusUpgradeViewSource {
        .files
    }
}
