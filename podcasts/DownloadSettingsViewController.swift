import PocketCastsDataModel
import UIKit

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

    private enum TableRow { case upNext, podcastAutoDownload, podcastSelection, filterSelection, onlyOnWifi }
    private let podcastDownloadOffData: [[TableRow]] = [[.upNext], [.podcastAutoDownload], [.filterSelection], [.onlyOnWifi]]
    private let podcastDownloadOnData: [[TableRow]] = [[.upNext], [.podcastAutoDownload, .podcastSelection], [.filterSelection], [.onlyOnWifi]]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsAutoDownload
        NotificationCenter.default.addObserver(self, selector: #selector(podcastUpdated(_:)), name: Constants.Notifications.podcastUpdated, object: nil)
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: settingsTable)
        Analytics.track(.settingsAutoDownloadShown)
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

        if firstRowInSection == .upNext {
            return L10n.settingsAutoDownloadsSubtitleUpNext
        } else if firstRowInSection == .podcastAutoDownload {
            return L10n.settingsAutoDownloadsSubtitleNewEpisodes
        } else if firstRowInSection == .filterSelection {
            return L10n.settingsAutoDownloadsSubtitleFilters
        }

        return nil
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
        case .filterSelection:
            let cell = tableView.dequeueReusableCell(withIdentifier: DownloadSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell

            let autoDownloadFilterCount = FilterManager.autoDownloadFilterCount()

            let filterStr = autoDownloadFilterCount == 1 ? L10n.settingsAutoDownloadsFiltersSelectedSingular : L10n.settingsAutoDownloadsFiltersSelectedFormat(autoDownloadFilterCount.localized())
            cell.cellLabel.text = autoDownloadFilterCount > 0 ? filterStr : L10n.settingsAutoDownloadsNoFiltersSelected
            cell.cellSecondaryLabel.text = ""

            return cell
        case .onlyOnWifi:
            let cell = tableView.dequeueReusableCell(withIdentifier: DownloadSettingsViewController.switchCellId, for: indexPath) as! SwitchCell

            cell.cellLabel.text = L10n.onlyOnWifi
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

        if row == .podcastSelection {
            podcastChooserController = PodcastChooserViewController()
            if let podcastSelectController = podcastChooserController {
                podcastSelectController.delegate = self
                let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
                podcastSelectController.selectedUuids = allPodcasts.filter { $0.autoDownloadOn() }.map(\.uuid)
                navigationController?.pushViewController(podcastSelectController, animated: true)
            }
        } else if row == .filterSelection {
            let filterSelectionViewController = FilterSelectionViewController()
            filterSelectionViewController.allFilters = DataManager.sharedManager.allFilters(includeDeleted: false)
            let selectedFilters = DataManager.sharedManager.allFilters(includeDeleted: false).compactMap { filter -> String? in
                filter.autoDownloadEpisodes ? filter.uuid : nil
            }
            filterSelectionViewController.selectedFilters = selectedFilters
            filterSelectionViewController.filterSelected = { filter in
                filter.autoDownloadEpisodes = true
                filter.autoDownloadLimit = filter.maxAutoDownloadEpisodes()
                DataManager.sharedManager.save(filter: filter)
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged, object: filter)
            }
            filterSelectionViewController.filterUnselected = { filter in
                filter.autoDownloadEpisodes = false
                DataManager.sharedManager.save(filter: filter)
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged, object: filter)
            }
            filterSelectionViewController.didChangeFilters = {
                Analytics.track(.settingsAutoDownloadFiltersChanged)
            }

            navigationController?.pushViewController(filterSelectionViewController, animated: true)
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

    func didChangePodcasts() {
        Analytics.track(.settingsAutoDownloadPodcastsChanged)
    }

    // MARK: - Switch Settings

    @objc private func automaticDownloadToggled(_ slider: UISwitch) {
        Settings.setAutoDownloadEnabled(slider.isOn, userInitiated: true)
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

        return autoDownloadPodcastsEnabled ? podcastDownloadOnData : podcastDownloadOffData
    }
}
