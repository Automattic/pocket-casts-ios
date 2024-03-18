import PocketCastsDataModel
import WatchKit

class FiltersInterfaceController: PCInterfaceController {
    @IBOutlet var filtersTable: WKInterfaceTable!
    @IBOutlet var loadingLabel: WKInterfaceLabel!

    private var watchFilters: [EpisodeFilter]?
    private var phoneFilters: [WatchFilter]?
    override func populateTitle() {
        setTitle(L10n.filters.prefixSourceUnicode)
    }

    override func handleDataUpdated() {
        reloadData()
    }

    func reloadData() {
        if SourceManager.shared.isPhone() {
            phoneFilters = WatchDataManager.filters()
        } else {
            watchFilters = DataManager.sharedManager.allFilters(includeDeleted: false)
        }

        reloadTable()
    }

    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        guard let filter: Filter = SourceManager.shared.isPhone() ? phoneFilters?[rowIndex] : watchFilters?[rowIndex] else { return }
        pushController(forType: .filter, context: FilterEpisodeListView.context(withFilter: filter))
    }

    private func reloadTable() {
        if SourceManager.shared.isPhone() {
            guard let filters = phoneFilters, filters.count > 0 else {
                handleNoDataAvailable()
                return
            }

            loadingLabel.setHidden(true)
            filtersTable.setNumberOfRows(filters.count, withRowType: "TopLevelItemRowController")

            for (index, filter) in filters.enumerated() {
                let row = filtersTable.rowController(at: index) as! TopLevelItemRowController
                row.populate(title: filter.title)
                row.icon.setImage(UIImage(named: filter.iconName ?? ""))
            }
        } else {
            guard let filters = watchFilters, filters.count > 0 else {
                handleNoDataAvailable()
                return
            }

            loadingLabel.setHidden(true)
            filtersTable.setNumberOfRows(filters.count, withRowType: "TopLevelItemRowController")

            for (index, filter) in filters.enumerated() {
                let row = filtersTable.rowController(at: index) as! TopLevelItemRowController
                if let imageName = filter.iconImageName() {
                    row.icon.setImage(UIImage(named: imageName))
                } else {
                    row.icon.setImage(UIImage(named: "filter_list"))
                }
                row.populate(title: filter.playlistName, count: DataManager.sharedManager.episodeCount(forFilter: filter, episodeUuidToAdd: filter.episodeUuidToAddToQueries()))
            }
        }
    }

    private func handleNoDataAvailable() {
        filtersTable.setNumberOfRows(0, withRowType: "TopLevelItemRowController")
        loadingLabel.setHidden(false)
        loadingLabel.setText(L10n.watchNoFilters)
    }

    // MARK: - Restorable Support

    override func restoreName() -> String? {
        "FiltersInterfaceController"
    }
}
