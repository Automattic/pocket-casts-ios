import PocketCastsDataModel
import UIKit
import PocketCastsUtils

class DownloadSettingsViewController: PCViewController, UITableViewDataSource, UITableViewDelegate, PodcastSelectionDelegate {
    private static let switchCellId = "SwitchCell"
    private static let disclosureCellId = "DisclosureCell"

    private var allPodcasts = [Podcast]()
    @IBOutlet var settingsTable: UITableView! {
        didSet {
            settingsTable.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: DownloadSettingsViewController.switchCellId)
            settingsTable.register(UINib(nibName: "DisclosureCell", bundle: nil), forCellReuseIdentifier: DownloadSettingsViewController.disclosureCellId)
        }
    }

    private enum TableRow { case upNext, podcastAutoDownload, podcastSelection, downloadOnFollow, downloadLimits, filterSelection, onlyOnWifi }
    private let podcastDownloadOffData: [[TableRow]] = [[.upNext], [.podcastAutoDownload], [.filterSelection], [.onlyOnWifi]]
    private let podcastDownloadOnData: [[TableRow]] = [[.upNext], [.podcastAutoDownload, .podcastSelection], [.filterSelection], [.onlyOnWifi]]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsAutoDownload
        NotificationCenter.default.addObserver(self, selector: #selector(podcastUpdated(_:)), name: Constants.Notifications.podcastUpdated, object: nil)
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: settingsTable)
        Analytics.track(.settingsAutoDownloadShown)
        ManageDownloadsCoordinator.showModalIfNeeded(from: self, source: "auto_download")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        settingsTable.reloadData()
    }

    // MARK: - UITableView methods

    func numberOfSections(in tableView: UITableView) -> Int {
        tableRows().count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerFrame = CGRect(x: 0, y: 0, width: 0, height: Constants.Values.tableSectionHeaderHeight)

        let firstRowInSection = tableRows()[section][0]
        return firstRowInSection == .onlyOnWifi ? SettingsTableHeader(frame: headerFrame, title: L10n.settings.localizedUppercase) : nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Constants.Values.tableSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let firstRowInSection = tableRows()[section][0]

        switch firstRowInSection {
        case .upNext:
            return L10n.settingsAutoDownloadsSubtitleUpNext
        case .podcastAutoDownload:
            return L10n.settingsAutoDownloadsSubtitleNewEpisodes
        case .filterSelection:
            return FeatureFlag.playlistsRebranding.enabled ? L10n.settingsAutoDownloadsSubtitlePlaylists : L10n.settingsAutoDownloadsSubtitleFilters
        case .onlyOnWifi:
            return L10n.onlyOnUnmeteredWifiDetails
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableRows()[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = tableRows()[indexPath.section][indexPath.row]

        switch row {
        case .upNext:
            let cell = tableView.dequeueReusableCell(withIdentifier: DownloadSettingsViewController.switchCellId, for: indexPath) as! SwitchCell

            cell.cellLabel.text = L10n.upNext
            cell.cellSwitch.isOn = Settings.downloadUpNextEpisodes()
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(downloadUpNextToggled(_:)), for: UIControl.Event.valueChanged)

            return cell
        case .podcastAutoDownload:
            let cell = tableView.dequeueReusableCell(withIdentifier: DownloadSettingsViewController.switchCellId, for: indexPath) as! SwitchCell

            cell.cellLabel.text = L10n.newEpisodes.localizedCapitalized
            cell.cellSwitch.isOn = Settings.autoDownloadEnabled()
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(automaticDownloadToggled(_:)), for: UIControl.Event.valueChanged)

            return cell
        case .podcastSelection:
            let cell = tableView.dequeueReusableCell(withIdentifier: DownloadSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell

            let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
            let allWithAutoDownloadOn = allPodcasts.filter { $0.autoDownloadOn() }

            cell.cellLabel.text = L10n.selectedPodcastCount(allWithAutoDownloadOn.count)
            cell.cellSecondaryLabel.text = ""

            return cell
        case .downloadOnFollow:
            let cell = tableView.dequeueReusableCell(withIdentifier: DownloadSettingsViewController.switchCellId, for: indexPath) as! SwitchCell

            cell.cellLabel.text = L10n.settingsAutoDownloadsOnFollow
            cell.cellSwitch.isOn = Settings.autoDownloadOnFollow()
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(automaticDownloadOnFollowToggled(_:)), for: UIControl.Event.valueChanged)

            return cell
        case .downloadLimits:
            let cell = tableView.dequeueReusableCell(withIdentifier: DownloadSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell

            cell.cellLabel.text = L10n.autoDownloadLimitDownloads
            cell.cellSecondaryLabel.text = Settings.autoDownloadLimits().localizedDescriptionForRow

            return cell
        case .filterSelection:
            let cell = tableView.dequeueReusableCell(withIdentifier: DownloadSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell

            let autoDownloadPlaylistsCount = PlaylistManager.autoDownloadPlaylistsCount()
            let playlistRebrandingEnabled = FeatureFlag.playlistsRebranding.enabled
            let singularPlaylistString = playlistRebrandingEnabled ? L10n.settingsAutoDownloadsPlaylistsSelectedSingular : L10n.settingsAutoDownloadsFiltersSelectedSingular
            let pluralPlaylistString = playlistRebrandingEnabled ? L10n.settingsAutoDownloadsPlaylistsSelectedFormat(autoDownloadPlaylistsCount.localized()) : L10n.settingsAutoDownloadsFiltersSelectedFormat(autoDownloadPlaylistsCount.localized())
            let noPlaylistString = playlistRebrandingEnabled ? L10n.settingsAutoDownloadsNoPlaylistsSelected : L10n.settingsAutoDownloadsNoFiltersSelected
            let playlistStr = autoDownloadPlaylistsCount == 1 ? singularPlaylistString : pluralPlaylistString
            cell.cellLabel.text = autoDownloadPlaylistsCount > 0 ? playlistStr : noPlaylistString
            cell.cellSecondaryLabel.text = ""

            return cell
        case .onlyOnWifi:
            let cell = tableView.dequeueReusableCell(withIdentifier: DownloadSettingsViewController.switchCellId, for: indexPath) as! SwitchCell

            cell.cellLabel.text = L10n.onlyOnUnmeteredWifi
            cell.cellSwitch.isOn = !Settings.autoDownloadMobileDataAllowed()
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(useMobileDataToggled(_:)), for: UIControl.Event.valueChanged)

            return cell
        }
    }

    private var podcastChooserController: PodcastChooserViewController?

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = tableRows()[indexPath.section][indexPath.row]

        switch row {
        case .podcastSelection:
            podcastChooserController = PodcastChooserViewController()
            podcastChooserController?.analyticsSource = .downloads
            if let podcastSelectController = podcastChooserController {
                podcastSelectController.delegate = self
                let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
                podcastSelectController.selectedUuids = allPodcasts.filter { $0.autoDownloadOn() }.map(\.uuid)
                navigationController?.pushViewController(podcastSelectController, animated: true)
            }
        case .filterSelection:
            let playlistSelectionViewController = PlaylistSelectionViewController()
            playlistSelectionViewController.navigationTitle = FeatureFlag.playlistsRebranding.enabled ? L10n.settingsSelectPlaylistsPlural : L10n.settingsSelectFiltersPlural
            playlistSelectionViewController.allPlaylists = DataManager.sharedManager.allPlaylists(includeDeleted: false)
            let selectedFilters = DataManager.sharedManager.allPlaylists(includeDeleted: false).compactMap { playlist -> String? in
                playlist.autoDownloadEpisodes ? playlist.uuid : nil
            }
            playlistSelectionViewController.selectedPlaylists = selectedFilters
            playlistSelectionViewController.playlistSelected = { playlist in
                Analytics.track(.filterAutoDownloadUpdated, properties: ["enabled": true, "source": AnalyticsSource.autoDownloadSettings])
                playlist.autoDownloadEpisodes = true
                playlist.autoDownloadLimit = playlist.maxAutoDownloadEpisodes()
                DataManager.sharedManager.save(playlist: playlist)
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: playlist)
            }
            playlistSelectionViewController.playlistUnselected = { playlist in
                Analytics.track(.filterAutoDownloadUpdated, properties: ["enabled": false, "source": AnalyticsSource.autoDownloadSettings])
                playlist.autoDownloadEpisodes = false
                DataManager.sharedManager.save(playlist: playlist)
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: playlist)
            }
            playlistSelectionViewController.didChangePlaylist = {
                Analytics.track(.settingsAutoDownloadFiltersChanged)
            }

            navigationController?.pushViewController(playlistSelectionViewController, animated: true)
        case .downloadLimits:
            let picker = OptionsPicker(title: L10n.autoDownloadLimitAutoDownloads)
            let limitOptions = AutoDownloadLimit.allCases
            for limit in limitOptions {
                let selectAction = OptionAction(label: limit.localizedDescriptionForOption, selected: Settings.autoDownloadLimits() == limit) {
                    Settings.setAutoDownloadLimits(limit)
                    tableView.reloadData()
                }
                picker.addAction(action: selectAction)
            }
            picker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
        default:
            break
        }
    }

    // MARK: - Notification handler

    @objc func podcastUpdated(_ notification: Notification) {
        guard let podcastChooserController = podcastChooserController else { return }
        let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
        podcastChooserController.selectedUuids = allPodcasts.filter { $0.autoDownloadOn() }.map(\.uuid)
        podcastChooserController.selectedUuidsUpdated = true
    }

    // MARK: - PodcastSelectionDelegate

    func bulkSelectionChange(selected: Bool) {
        let setting: AutoDownloadSetting = selected ? .latest : .off
        DataManager.sharedManager.setDownloadSettingForAllPodcasts(setting: setting)
        let allPodcastsChanged = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
        allPodcastsChanged.forEach { NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: $0.uuid) }
    }

    func podcastSelected(podcast: String) {
        DataManager.sharedManager.savePodcastDownloadSetting(.latest, podcastUuid: podcast)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast)
    }

    func podcastUnselected(podcast: String) {
        DataManager.sharedManager.savePodcastDownloadSetting(.off, podcastUuid: podcast)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast)
    }

    func didChangePodcasts(numberSelected: Int) {
        Analytics.track(.settingsAutoDownloadPodcastsChanged, properties: ["number_selected": numberSelected])
    }

    // MARK: - Switch Settings

    @objc private func automaticDownloadToggled(_ slider: UISwitch) {
        Settings.setAutoDownloadEnabled(slider.isOn, userInitiated: true)
        settingsTable.reloadData()
    }

    @objc private func automaticDownloadOnFollowToggled(_ slider: UISwitch) {
        Settings.setAutoDownloadOnFollow(slider.isOn, userInitiated: true)
        settingsTable.reloadData()
    }

    @objc private func downloadUpNextToggled(_ slider: UISwitch) {
        Settings.setDownloadUpNextEpisodes(slider.isOn)

        settingsTable.reloadData()
    }

    @objc private func useMobileDataToggled(_ slider: UISwitch) {
        Settings.setAutoDownloadMobileDataAllowed(!slider.isOn, userInitiated: true)
    }

    private func tableRows() -> [[TableRow]] {
        let autoDownloadPodcastsEnabled = Settings.autoDownloadEnabled()

        var data = autoDownloadPodcastsEnabled ? podcastDownloadOnData : podcastDownloadOffData

        if FeatureFlag.autoDownloadOnSubscribe.enabled {
            data = podcastDownloadOnData
            data[1].append(.downloadOnFollow)
            data[1].append(.downloadLimits)
            if !autoDownloadPodcastsEnabled {
                data[1].remove(at: 1)
            }
        }

        return data
    }
}

extension AutoDownloadLimit {

    var localizedDescriptionForRow: String {
        switch self {
        case .one:
            return L10n.autoDownloadLimitOneEpisode
        default:
            return L10n.autoDownloadLimitNumberOfEpisodes(self.rawValue)
        }
    }

    var localizedDescriptionForOption: String {
        switch self {
        case .one:
            return L10n.autoDownloadLimitOneEpisodeShow
        default:
            return L10n.autoDownloadLimitNumberOfEpisodesShow(self.rawValue)
        }
    }

}
