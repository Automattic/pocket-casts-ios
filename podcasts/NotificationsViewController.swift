import PocketCastsDataModel
import PocketCastsServer
import UIKit

class NotificationsViewController: PCViewController, UITableViewDataSource, UITableViewDelegate, PodcastSelectionDelegate {
    private let switchCellId = "SwitchCell"
    private let disclosureCellId = "DisclosureCell"

    private let soundOff = 0

    @IBOutlet var settingsTable: UITableView! {
        didSet {
            settingsTable.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: switchCellId)
            settingsTable.register(UINib(nibName: "DisclosureCell", bundle: nil), forCellReuseIdentifier: disclosureCellId)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsNotifications
        NotificationCenter.default.addObserver(self, selector: #selector(podcastUpdated(_:)), name: Constants.Notifications.podcastUpdated, object: nil)

        Analytics.track(.settingsNotificationsShown)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        settingsTable.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NotificationsHelper.shared.pushEnabled() ? 3 : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = L10n.newEpisodes.localizedCapitalized
            cell.cellSwitch.isOn = NotificationsHelper.shared.pushEnabled()

            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(pushToggled(_:)), for: UIControl.Event.valueChanged)

            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCellId, for: indexPath) as! DisclosureCell
            let podcastsSelected = DataManager.sharedManager.pushEnabledPodcastsCount()
            let chosenPodcasts = podcastsSelected == 1 ? L10n.chosenPodcastsSingular : L10n.chosenPodcastsPluralFormat(podcastsSelected.localized())
            cell.cellLabel.text = (podcastsSelected == 0) ? L10n.filterChoosePodcasts : chosenPodcasts
            cell.cellSecondaryLabel.text = nil

            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCellId, for: indexPath) as! DisclosureCell
        cell.cellLabel.text = L10n.appBadge
        let badgeChoice = Settings.appBadge

        switch badgeChoice {
        case .totalUnplayed:
            cell.cellSecondaryLabel.text = L10n.statusUnplayed
        case .filterCount:
            cell.cellSecondaryLabel.text = L10n.settingsNotificationsFilterCount
        case .newSinceLastOpened:
            cell.cellSecondaryLabel.text = L10n.newEpisodes
        default:
            cell.cellSecondaryLabel.text = L10n.off
        }
        return cell
    }

    private var podcastChooserController: PodcastChooserViewController?
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 1 { // choose podcasts for push
            podcastChooserController = PodcastChooserViewController()
            if let podcastsController = podcastChooserController {
                podcastsController.delegate = self
                let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
                podcastsController.selectedUuids = allPodcasts.filter(\.isPushEnabled).map(\.uuid)
                navigationController?.pushViewController(podcastsController, animated: true)
            }
        } else if indexPath.row == 2 { // app badge
            let badgeSettingsChooser = BadgeSettingsViewController(nibName: "BadgeSettingsViewController", bundle: nil)
            navigationController?.pushViewController(badgeSettingsChooser, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        NotificationsHelper.shared.pushEnabled() ? nil : L10n.settingsNotificationsSubtitle
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }

    // MARK: - Notification handler

    @objc func podcastUpdated(_ notification: Notification) {
        guard let podcastChooserController = podcastChooserController else { return }
        let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
        podcastChooserController.selectedUuids = allPodcasts.filter(\.isPushEnabled).map(\.uuid)
        podcastChooserController.selectedUuidsUpdated = true
    }

    // MARK: - PodcastSelectionDelegate

    func bulkSelectionChange(selected: Bool) {
        DataManager.sharedManager.setPushForAllPodcasts(pushEnabled: selected)
        let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
        allPodcasts.forEach { NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: $0.uuid) }
    }

    func podcastSelected(podcast: String) {
        DataManager.sharedManager.savePushSetting(podcastUuid: podcast, pushEnabled: true)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast)
    }

    func podcastUnselected(podcast: String) {
        DataManager.sharedManager.savePushSetting(podcastUuid: podcast, pushEnabled: false)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast)
    }

    func didChangePodcasts() {
        Analytics.track(.settingsNotificationsPodcastsChanged)
    }

    @objc private func pushToggled(_ sender: UISwitch) {
        //  UserDefaults.standard.set(sender.isOn, forKey: Constants.UserDefaults.pushEnabled)

        if sender.isOn {
            NotificationsHelper.shared.enablePush()
            // the user has just turned on push, enable it for all their podcasts for simplicity
            DataManager.sharedManager.setPushForAllPodcasts(pushEnabled: true)
            NotificationsHelper.shared.registerForPushNotifications()
        } else {
            NotificationsHelper.shared.disablePush()
            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
        }

        Settings.trackValueToggled(.settingsNotificationsNewEpisodesToggled, enabled: sender.isOn)

        settingsTable.reloadData()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }
}
