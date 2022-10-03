import UIKit

class ReleaseDateFilterViewController: FilterSettingsViewController, UITableViewDataSource, UITableViewDelegate {
    var choices = ["Last 24 hours", "Last 3 days", "Last week", "Last 2 weeks", "Last month", "Anytime"]
    var selectedValue = 0
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        tableView.separatorStyle = .none

        setCurrentReleaseDate()
    }

    // MAKR: - TableView DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        6
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "ReleaseFilterCell")

        cell.textLabel?.text = choices[indexPath.row]
        cell.accessoryType = indexPath.row == selectedValue ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let oldSelectedValue = selectedValue
        selectedValue = indexPath.row
        filterToEdit.filterHours = timeToFilterLenght(filterName: choices[indexPath.row])
        tableView.reloadRows(at: [indexPath, IndexPath(row: oldSelectedValue, section: 0)], with: .automatic)
    }

    func timeToFilterLenght(filterName: String) -> Int32 {
        if filterName.caseInsensitiveCompare("Anytime") == .orderedSame {
            return 0
        } else if filterName.caseInsensitiveCompare("Last 24 hours") == .orderedSame {
            return 24
        } else if filterName.caseInsensitiveCompare("Last 3 days") == .orderedSame {
            return (24 * 3)
        } else if filterName.caseInsensitiveCompare("Last week") == .orderedSame {
            return (24 * 7)
        } else if filterName.caseInsensitiveCompare("Last 2 weeks") == .orderedSame {
            return (24 * 14)
        } else if filterName.caseInsensitiveCompare("Last month") == .orderedSame {
            return (24 * 31)
        } else {
            // fallback in case another client sets some weird amount of hours
            return filterToEdit.filterHours
        }
    }

    func setCurrentReleaseDate() {
        if filterToEdit.filterHours <= 0 {
            selectedValue = 5
        }
        if filterToEdit.filterHours == 24 {
            selectedValue = 0
        } else if filterToEdit.filterHours == (24 * 3) {
            selectedValue = 1
        } else if filterToEdit.filterHours == (24 * 7) {
            selectedValue = 2
        } else if filterToEdit.filterHours == (24 * 14) {
            selectedValue = 3
        } else if filterToEdit.filterHours == (24 * 31) {
            selectedValue = 4
        } else {
            // fallback in case another client sets some weird amount of hours
            // TODO: return "\(filterHours) hours";
            selectedValue = 0
        }
    }
}
