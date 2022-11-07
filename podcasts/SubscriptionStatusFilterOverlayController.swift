import UIKit

//class SubscriptionStatusFilterOverlayController: FilterSettingsOverlayController, UITableViewDataSource, UITableViewDelegate

import UIKit

class SubscriptionStatusFilterOverlayController: FilterSettingsOverlayController, UITableViewDataSource, UITableViewDelegate {
    private static let subscriptionStatusCellId = "RadioButtonCellId"

    private enum TableRow: Int { case all, subscribed, notSubscribed }
    private static let tableData: [TableRow] = [.all, .subscribed, .notSubscribed]

    private var selectedRow: TableRow = .subscribed

    override var analyticsSource: AnalyticsSource {
        .subscriptionStatus
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "RadioButtonCell", bundle: nil), forCellReuseIdentifier: SubscriptionStatusFilterOverlayController.subscriptionStatusCellId)
        addTableViewHeader()

        setupLargeTitle()
        title = L10n.filterSubscriptionStatus
        tableView.contentInsetAdjustmentBehavior = .never
        setCurrentSubscriptionStatus()
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        addCloseButton()
    }

    // MARK: - TableView DataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        SubscriptionStatusFilterOverlayController.tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SubscriptionStatusFilterOverlayController.subscriptionStatusCellId) as! RadioButtonCell
        let row = SubscriptionStatusFilterOverlayController.tableData[indexPath.row]
        cell.title.text = titleForRow(row: row)
        cell.title.setLetterSpacing(-0.2)
        cell.setSelectState(selectedRow == row)
        let filterTintColor = filterToEdit.playlistColor()
        cell.setTintColor(color: filterTintColor)
        cell.style = .primaryUi01
        cell.selectButton.tag = indexPath.row
        cell.selectButton.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRow = SubscriptionStatusFilterOverlayController.tableData[indexPath.row]
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        51
    }

    // MARK: - Helper functions

    override func saveFilter() {
        switch selectedRow {
        case .all:
            filterToEdit.filterSubscribed = true
            filterToEdit.filterNotSubscribed = true
        case .subscribed:
            filterToEdit.filterSubscribed = true
            filterToEdit.filterNotSubscribed = false
        case .notSubscribed:
            filterToEdit.filterSubscribed = false
            filterToEdit.filterNotSubscribed = true
        }
        super.saveFilter()
    }

    @objc func selectButtonTapped(_ sender: AnyObject) {
        guard let buttonTag = sender.tag else { return }

        selectedRow = SubscriptionStatusFilterOverlayController.tableData[buttonTag]
        tableView.reloadData()
    }

    private func setCurrentSubscriptionStatus() {
        if filterToEdit.filterNotSubscribed, !filterToEdit.filterSubscribed {
            selectedRow = .notSubscribed
        } else if !filterToEdit.filterNotSubscribed, filterToEdit.filterSubscribed {
            selectedRow = .subscribed
        } else {
            selectedRow = .all
        }
    }

    private func titleForRow(row: TableRow) -> String {
        switch row {
        case .all:
            return L10n.filterValueAll
        case .subscribed:
            return L10n.statusSubscribed
        case .notSubscribed:
            return L10n.statusNotSubscribed
        }
    }
}
