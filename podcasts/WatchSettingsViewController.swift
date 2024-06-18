import PocketCastsServer
import UIKit

class WatchSettingsViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    private let switchCellId = "SwitchCell"
    private let lockInfoCellId = "LockCell"
    private let disclosureCellId = "DisclosureCell"

    private enum TableSections: Int { case upNext, lockedInfo }
    private enum TableRows: Int { case autoDownloadUpNext, numUpNextEpisodes, autoDeleteUpNext, lockedInfo }
    private let autoDownloadCounts = [3, 5, 8, 10]
    @IBOutlet var settingsTable: UITableView! {
        didSet {
            settingsTable.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: switchCellId)
            settingsTable.register(UINib(nibName: "PlusLockedInfoCell", bundle: nil), forCellReuseIdentifier: lockInfoCellId)
            settingsTable.register(UINib(nibName: "DisclosureCell", bundle: nil), forCellReuseIdentifier: disclosureCellId)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.appleWatch
        addCustomObserver(ServerNotifications.subscriptionStatusChanged, selector: #selector(subscriptionStatusChanged))
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: settingsTable)
        Analytics.track(.settingsAppleWatchShown)
    }

    @objc func subscriptionStatusChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.settingsTable.reloadData()
        }
    }

    private func tableSections() -> [TableSections] {
        var sections: [TableSections] = [.upNext]
        if !SubscriptionHelper.hasActiveSubscription(), !Settings.plusInfoDismissedOnWatch() {
            sections.append(.lockedInfo)
        }

        return sections
    }

    private func tableRows() -> [[TableRows]] {
        let hasSubscription = SubscriptionHelper.hasActiveSubscription()

        var rows: [[TableRows]] = [[.autoDownloadUpNext]]
        if hasSubscription, Settings.watchAutoDownloadUpNextEnabled() {
            rows[0].append(.numUpNextEpisodes)
            rows[0].append(.autoDeleteUpNext)
        }
        if !hasSubscription, !Settings.plusInfoDismissedOnWatch() {
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

        switch row {
        case .autoDownloadUpNext:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellLabel?.text = L10n.settingsWatchAutoDownload
            cell.cellSwitch.isOn = Settings.watchAutoDownloadUpNextEnabled()
            cell.cellSwitch.addTarget(self, action: #selector(upNextToggled(_:)), for: .valueChanged)
            cell.isLocked = SubscriptionHelper.hasActiveSubscription()
            cell.imageView?.isHidden = true
            return cell
        case .lockedInfo:
            let cell = tableView.dequeueReusableCell(withIdentifier: lockInfoCellId, for: indexPath) as! PlusLockedInfoCell
            cell.lockView.delegate = self
            return cell
        case .numUpNextEpisodes:
            let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel?.text = L10n.settingsWatchEpisodeLimit
            cell.cellSecondaryLabel?.text = L10n.settingsWatchEpisodeNumberOptionFormat(Settings.watchAutoDownloadUpNextCount().localized())
            return cell
        case .autoDeleteUpNext:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellLabel?.text = L10n.settingsWatchDeleteDownloads
            cell.cellSwitch.isOn = Settings.watchAutoDeleteUpNext()
            cell.cellSwitch.addTarget(self, action: #selector(upNextAutoDeleteToggled(_:)), for: .valueChanged)
            cell.isLocked = SubscriptionHelper.hasActiveSubscription()
            cell.imageView?.isHidden = true
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = tableSections()[indexPath.section]
        if section == .lockedInfo {
            return 161
        }
        return 56
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let section = tableSections()[section]
        if section == .upNext {
            let footerHeight: CGFloat = UIScreen.main.bounds.width > 350 ? 130 : 170
            let footer = UIView(frame: CGRect(x: 0, y: 0, width: settingsTable.bounds.width, height: footerHeight))
            let infoLabel = ThemeableLabel()
            infoLabel.style = .primaryText02

            let numEpisodes = Settings.watchAutoDownloadUpNextEnabled() == true ? Settings.watchAutoDownloadUpNextCount() : 5

            var infoText: String
            var useSmallTextBox = true
            if Settings.watchAutoDownloadUpNextEnabled() {
                useSmallTextBox = false
                infoText = L10n.settingsWatchEpisodeLimitSubtitle(numEpisodes.localized())

                let secondInfoTextLine: String
                if Settings.watchAutoDeleteUpNext() {
                    secondInfoTextLine = L10n.settingsWatchDeleteDownloadsOnSubtitle
                } else {
                    secondInfoTextLine = L10n.settingsWatchDeleteDownloadsOffSubtitle
                }

                infoText.append("\n\n" + secondInfoTextLine)
            } else {
                infoText = L10n.settingsWatchAutoDownloadOffSubtitle
            }

            infoLabel.text = infoText
            infoLabel.numberOfLines = 0
            infoLabel.font = UIFont.systemFont(ofSize: 13)
            infoLabel.translatesAutoresizingMaskIntoConstraints = false
            footer.addSubview(infoLabel)
            let bottomContraintConstant: CGFloat = useSmallTextBox ? -50 : 0
            NSLayoutConstraint.activate([
                infoLabel.topAnchor.constraint(equalTo: footer.topAnchor, constant: 6),
                infoLabel.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 16),
                infoLabel.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -16),
                infoLabel.bottomAnchor.constraint(equalTo: footer.bottomAnchor, constant: bottomContraintConstant)
            ])

            return footer
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let section = tableSections()[section]
        if section == .upNext {
            return UIScreen.main.bounds.width > 350 ? 130 : 170
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let thisSection = tableSections()[section]
        if thisSection == .upNext {
            return Constants.Values.tableSectionHeaderHeight
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerFrame = CGRect(x: 0, y: 0, width: 0, height: Constants.Values.tableSectionHeaderHeight)
        let title: String
        let section = tableSections()[section]
        switch section {
        case .upNext:
            title = L10n.plusFeatures
        default:
            return nil
        }

        let showLockIcon = (!SubscriptionHelper.hasActiveSubscription() && section == .upNext)
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

        if !SubscriptionHelper.hasActiveSubscription(), section == .upNext {
            showSubscriptionRequired()
            return
        }
        let row = tableRows()[indexPath.section][indexPath.row]

        switch row {
        case .numUpNextEpisodes:
            let upNextPicker = OptionsPicker(title: L10n.settingsWatchEpisodeLimit)
            for numEpisodes in autoDownloadCounts {
                let action = OptionAction(label: L10n.settingsWatchEpisodeNumberOptionFormat(numEpisodes.localized()), selected: numEpisodes == Settings.watchAutoDownloadUpNextCount(), action: {
                    Settings.setWatchAutoDownloadUpNextCount(numEpisodes: numEpisodes)
                    self.settingsTable.reloadData()
                    NotificationCenter.postOnMainThread(notification: Constants.Notifications.watchAutoDownloadSettingsChanged)
                })

                upNextPicker.addAction(action: action)
            }
            upNextPicker.show(statusBarStyle: preferredStatusBarStyle)
        case .autoDownloadUpNext:
            if let cell = settingsTable.cellForRow(at: indexPath) as? SwitchCell {
                upNextToggled(cell.cellSwitch)
            }
        case .autoDeleteUpNext:
            if let cell = settingsTable.cellForRow(at: indexPath) as? SwitchCell {
                upNextAutoDeleteToggled(cell.cellSwitch)
            }
        case .lockedInfo:
            showSubscriptionRequired()
        }
    }

    @objc func showSubscriptionRequired() {
        NavigationManager.sharedManager.showUpsellView(from: self, source: .watch)
    }

    // MARK: - Switch Actions

    @objc private func upNextToggled(_ sender: UISwitch) {
        Settings.setWatchAutoDownloadUpNextEnabled(isEnabled: sender.isOn)
        settingsTable.reloadData()
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.watchAutoDownloadSettingsChanged)
    }

    @objc private func upNextAutoDeleteToggled(_ sender: UISwitch) {
        Settings.setWatchAutoDeleteUpNext(isEnabled: sender.isOn)
        settingsTable.reloadData()
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.watchAutoDownloadSettingsChanged)
    }
}

// MARK: - PlusLockedInfoDelegate

extension WatchSettingsViewController: PlusLockedInfoDelegate {
    func closeInfoTapped() {
        Settings.setPlusInfoDismissedOnWatch(true)
        settingsTable.reloadData()
    }

    var displayingViewController: UIViewController {
        self
    }

    var displaySource: PlusUpgradeViewSource {
        .watch
    }
}
