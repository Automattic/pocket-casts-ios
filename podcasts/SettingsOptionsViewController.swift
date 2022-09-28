import UIKit

class SettingsOptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let cellId = "TopLevelSettingsCell"

    var explanationText: String?
    var saveOnChange = false
    @IBOutlet var optionsTable: UITableView? {
        didSet {
            optionsTable?.register(UINib(nibName: "TopLevelSettingsCell", bundle: nil), forCellReuseIdentifier: cellId)
        }
    }

    private var settingsKey: String?
    private var selectedItem = -1
    private var choices: [String]
    private var itemSelected: ((Int) -> Void)?

    private var changeWasMade = false

    @objc init(items: [String], settingsKey: String) {
        choices = items
        self.settingsKey = settingsKey
        selectedItem = UserDefaults.standard.integer(forKey: settingsKey)

        super.init(nibName: "SettingsOptionsViewController", bundle: nil)
    }

    @objc init(items: [String], selectedValue: Int, itemSelected: @escaping (Int) -> Void) {
        choices = items
        selectedItem = selectedValue
        self.itemSelected = itemSelected
        super.init(nibName: "SettingsOptionsViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if changeWasMade, !saveOnChange {
            saveChanges()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        choices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let castCell = cell as? TopLevelSettingsCell else { return }

        castCell.settingsLabel.text = choices[safe: indexPath.row]
        castCell.accessoryType = selectedItem == indexPath.row ? .checkmark : .none
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if selectedItem == indexPath.row { return } // already selected

        selectedItem = indexPath.row
        changeWasMade = true

        if saveOnChange {
            saveChanges()
        }

        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        explanationText
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }

    private func saveChanges() {
        if let settingsKey = settingsKey {
            UserDefaults.standard.set(selectedItem, forKey: settingsKey)
        } else {
            itemSelected?(selectedItem)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }
}
