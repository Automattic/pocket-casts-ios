import PocketCastsDataModel
import UIKit

class FilterSelectionViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    private static let filterAutoDownloadCell = "FilterDownloadCell"

    var allFilters = [EpisodeFilter]()
    var selectedFilters = [String]()
    var filterSelected: ((EpisodeFilter) -> Void)?
    var filterUnselected: ((EpisodeFilter) -> Void)?

    private var didChange = false
    var didChangeFilters: (() -> Void)?

    @IBOutlet var filterSelectionTable: UITableView! {
        didSet {
            filterSelectionTable.register(UINib(nibName: "FilterDownloadCell", bundle: nil), forCellReuseIdentifier: FilterSelectionViewController.filterAutoDownloadCell)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        filterSelectionTable.reloadData()
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: filterSelectionTable)
        title = L10n.settingsSelectFiltersPlural
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if didChange {
            didChangeFilters?()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        allFilters.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FilterSelectionViewController.filterAutoDownloadCell, for: indexPath) as! FilterDownloadCell

        let filter = allFilters[indexPath.row]
        cell.populateFrom(filter: filter, selected: selectedFilters.contains(filter.uuid))
        cell.filterSwitchToggled = { [weak self] selected in
            guard let self = self else { return }

            if selected {
                self.selectedFilters.append(filter.uuid)
                self.filterSelected?(filter)
            } else {
                self.selectedFilters.removeAll { $0 == filter.uuid }
                self.filterUnselected?(filter)
            }

            self.didChange = true
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // remove the standard padding from the top of a grouped UITableView
        section == 0 ? CGFloat.leastNonzeroMagnitude : 19
    }
}
