import IntentsUI
import PocketCastsDataModel
import UIKit

class FiltersShortcutsViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    var filters: [EpisodeFilter]!
    weak var delegate: SiriSettingsViewController?

    let addCellId = "siriAddCellId"
    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.settingsSelectFilterSingular
        tableView.register(UINib(nibName: "SiriShortcutAddCell", bundle: nil), forCellReuseIdentifier: addCellId)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filters.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: addCellId) as! SiriShortcutAddCell
        let filter = filters[indexPath.row]
        cell.populateFrom(filter: filter)
        cell.addIcon.isHidden = true
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        64
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let singleFilterVC = FilterShortcutsViewController(filter: filters[indexPath.row])
        navigationController?.pushViewController(singleFilterVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: false)
    }
}
