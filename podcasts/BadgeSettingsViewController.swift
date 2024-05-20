import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class BadgeSettingsViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    private let optionsSection = 0
    private let filtersSection = 1

    private let cellId = "TopLevelSettingsCell"

    var episodeFilters: [EpisodeFilter]!
    @IBOutlet var optionsTable: UITableView! {
        didSet {
            optionsTable.register(UINib(nibName: "TopLevelSettingsCell", bundle: nil), forCellReuseIdentifier: cellId)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        episodeFilters = DataManager.sharedManager.allFilters(includeDeleted: false)

        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: optionsTable)

        title = L10n.appBadge
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == optionsSection { return 3 }

        return episodeFilters.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerFrame = CGRect(x: 0, y: 0, width: 0, height: Constants.Values.tableSectionHeaderHeight)

        if section == optionsSection { return nil }

        return SettingsTableHeader(frame: headerFrame, title: L10n.settingsBadgeFilterHeader)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Constants.Values.tableSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! TopLevelSettingsCell
        cell.showsDisclosureIndicator = false

        if indexPath.section == optionsSection {
            if indexPath.row == 0 {
                cell.settingsLabel.text = L10n.off
            } else if indexPath.row == 1 {
                cell.settingsLabel.text = L10n.settingsBadgeTotalUnplayed
            } else if indexPath.row == 2 {
                cell.settingsLabel.text = L10n.settingsBadgeNewSinceOpened
            }

            let badgeSetting = Int(Settings.appBadge?.rawValue ?? AppBadge.off.rawValue)
            cell.accessoryType = (badgeSetting == indexPath.row) ? .checkmark : .none
        } else if indexPath.section == filtersSection, let filter = episodeFilters[safe: indexPath.row] {
            cell.settingsLabel.text = filter.playlistName

            let selectedFilterId = Settings.appBadgeFilterUuid
            cell.accessoryType = filter.uuid == selectedFilterId ? .checkmark : .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == optionsSection {
            Settings.appBadge = AppBadge(rawValue: Int32(indexPath.row))
            Settings.appBadgeFilterUuid = nil

            if let badge = AppBadge(rawValue: Int32(indexPath.row)) {
                Settings.trackValueChanged(.settingsNotificationsAppBadgeChanged, value: badge)
            }
        } else if indexPath.section == filtersSection {
            Settings.appBadge = AppBadge.filterCount
            if let filter = episodeFilters[safe: indexPath.row] {
                Settings.appBadgeFilterUuid = filter.uuid
            }
            Settings.trackValueChanged(.settingsNotificationsAppBadgeChanged, value: AppBadge.filterCount)
        }

        optionsTable.reloadData()
    }
}
