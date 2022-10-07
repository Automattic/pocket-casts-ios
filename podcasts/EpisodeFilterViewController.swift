import UIKit

class EpisodeFilterViewController: FilterSettingsViewController, UITableViewDataSource, UITableViewDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        tableView.separatorStyle = .none
    }

    // MAKR: - TableView DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "EpisodeFilterCell")

        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Unplayed"
                cell.accessoryType = .checkmark // filterToEdit.filterUnplayed?   .checkmark : .non
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "In Progress"
                cell.accessoryType = .checkmark
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Downloaded"
                cell.accessoryType = .checkmark
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Not Downloaded"
                cell.accessoryType = .checkmark
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
}
