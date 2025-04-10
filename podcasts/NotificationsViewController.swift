import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class NotificationsViewController: PCViewController, UITableViewDataSource, UITableViewDelegate, PodcastSelectionDelegate {
    private let switchCellId = "SwitchCell"
    private let disclosureCellId = "DisclosureCell"

    private let soundOff = 0

    private var sections: [Section] = [.episodes]
    private var rows: [[Row]] = [[.newEpisodes, .podcastsChosen, .appBadges], [.trendingRecommendations, .dailyReminders], [.newFeaturesAndTips, .pocketCastsOffers]]

    enum Section: Int {
        case episodes = 0
        case recommendationsAndReminders
        case featuresAndOffers
    }

    enum Row: Int {
        case newEpisodes
        case podcastsChosen
        case appBadges

        case trendingRecommendations
        case dailyReminders

        case newFeaturesAndTips
        case pocketCastsOffers

        var description: String {
            switch self {
            case .newEpisodes:
                return L10n.newEpisodes.localizedCapitalized
            case .podcastsChosen:
                return L10n.filterChoosePodcasts
            case .appBadges:
                return L10n.appBadge
            case .trendingRecommendations:
                return L10n.notificationsTrendingAndRecommendations
            case .dailyReminders:
                return L10n.notificationsDailyReminders
            case .newFeaturesAndTips:
                return L10n.notificationsNewFeaturesTips
            case .pocketCastsOffers:
                return L10n.notificationsPocketCastOffers
            }
        }

        var value: Bool {
        case .dailyReminders:
            return Settings.notificationsOnboardingTips
        case .newEpisodes,
                 .podcastsChosen, 
                 .appBadges,
                 .trendingRecommendations,
                 .newFeaturesAndTips,
                 .pocketCastsOffers:
            return false
            }
        }
    }

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

    func numberOfSections(in tableView: UITableView) -> Int {
        return FeatureFlag.notificationsRevamp.enabled ? 3 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else {
            return 0
        }
        switch sectionType {
        case .episodes:
            return NotificationsHelper.shared.pushEnabled() ? 3 : 1
        case .featuresAndOffers, .recommendationsAndReminders:
            return rows[section].count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        let row = rows[sectionType.rawValue][indexPath.row]
        switch row {
        case .newEpisodes:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = row.description
            cell.cellSwitch.isOn = NotificationsHelper.shared.pushEnabled()

            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(pushToggled(_:)), for: UIControl.Event.valueChanged)

            return cell
        case .podcastsChosen:
            let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCellId, for: indexPath) as! DisclosureCell
            let podcastsSelected = DataManager.sharedManager.pushEnabledPodcastsCount()
            let chosenPodcasts = podcastsSelected == 1 ? L10n.chosenPodcastsSingular : L10n.chosenPodcastsPluralFormat(podcastsSelected.localized())
            cell.cellLabel.text = (podcastsSelected == 0) ? L10n.filterChoosePodcasts : chosenPodcasts
            cell.cellSecondaryLabel.text = nil

            return cell
        case .appBadges:
            let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = row.description
            let badgeChoice = Settings.appBadge
            cell.cellSecondaryLabel.text =  badgeChoice?.description

            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = row.description
            cell.cellSwitch.isOn = row.value
            cell.cellSwitch.tag = row.rawValue
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(notificationToggled(_:)), for: UIControl.Event.valueChanged)

            return cell
        }
    }

    private var podcastChooserController: PodcastChooserViewController?
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let sectionType = Section(rawValue: indexPath.section)
        else {
            return
        }
        let rowType = rows[indexPath.section][indexPath.row]

        switch sectionType {
        case .episodes:
            switch rowType {
            case .podcastsChosen: // choose podcasts for push
                podcastChooserController = PodcastChooserViewController()
                podcastChooserController?.analyticsSource = .notifications
                if let podcastsController = podcastChooserController {
                    podcastsController.delegate = self
                    let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
                    podcastsController.selectedUuids = allPodcasts.filter(\.isPushEnabled).map(\.uuid)
                    navigationController?.pushViewController(podcastsController, animated: true)
                }
            case .appBadges: // app badge
                let badgeSettingsChooser = BadgeSettingsViewController(nibName: "BadgeSettingsViewController", bundle: nil)
                navigationController?.pushViewController(badgeSettingsChooser, animated: true)
            default:
                return
            }
        default:
            return
        }

    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else {
            return nil
        }
        switch sectionType {
        case .episodes:
            return NotificationsHelper.shared.pushEnabled() ? nil : L10n.settingsNotificationsSubtitle
        default:
            return nil
        }

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

    func didChangePodcasts(numberSelected: Int) {
        Analytics.track(.settingsNotificationsPodcastsChanged, properties: ["number_selected": numberSelected])
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

    @objc private func notificationToggled(_ sender: UISwitch) {
        guard let row = Row(rawValue: sender.tag) else {
            return
        }
        switch row {
        case .dailyReminders:
            if sender.isOn {
                NotificationsCoordinator.shared.setupOnboardingNotifications()
            } else {
                NotificationsCoordinator.shared.cancelOnboardingNotifications()
            }
        default:
            break
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }
}

extension AppBadge {

    var description: String {
        switch self {
        case .totalUnplayed:
            return L10n.statusUnplayed
        case .filterCount:
            return L10n.settingsNotificationsFilterCount
        case .newSinceLastOpened:
            return L10n.newEpisodes
        default:
            return L10n.off
        }
    }
}
