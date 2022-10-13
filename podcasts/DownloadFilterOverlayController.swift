import UIKit

class DownloadFilterOverlayController: FilterSettingsOverlayController, UITableViewDataSource, UITableViewDelegate {
    private static let downloadCellId = "RadioButtonCellId"

    private enum TableRow: Int { case all, downloaded, notDownloaded }
    private static let tableData: [TableRow] = [.all, .downloaded, .notDownloaded]

    private var selectedRow: TableRow = .all

    override var analyticsSource: AnalyticsSource {
        .downloadStatus
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "RadioButtonCell", bundle: nil), forCellReuseIdentifier: DownloadFilterOverlayController.downloadCellId)
        addTableViewHeader()

        setupLargeTitle()
        title = L10n.filterDownloadStatus
        tableView.contentInsetAdjustmentBehavior = .never
        setCurrentDownloadStatus()
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        addCloseButton()
    }

    // MARK: - TableView DataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        DownloadFilterOverlayController.tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DownloadFilterOverlayController.downloadCellId) as! RadioButtonCell
        let row = DownloadFilterOverlayController.tableData[indexPath.row]
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
        selectedRow = DownloadFilterOverlayController.tableData[indexPath.row]
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        51
    }

    // MARK: - Helper functions

    override func saveFilter() {
        switch selectedRow {
        case .all:
            filterToEdit.filterDownloaded = true
            filterToEdit.filterNotDownloaded = true
        case .downloaded:
            filterToEdit.filterDownloaded = true
            filterToEdit.filterNotDownloaded = false
        case .notDownloaded:
            filterToEdit.filterDownloaded = false
            filterToEdit.filterNotDownloaded = true
        }
        super.saveFilter()
    }

    @objc func selectButtonTapped(_ sender: AnyObject) {
        guard let buttonTag = sender.tag else { return }

        selectedRow = DownloadFilterOverlayController.tableData[buttonTag]
        tableView.reloadData()
    }

    private func setCurrentDownloadStatus() {
        if filterToEdit.filterNotDownloaded, !filterToEdit.filterDownloaded {
            selectedRow = .notDownloaded
        } else if !filterToEdit.filterNotDownloaded, filterToEdit.filterDownloaded {
            selectedRow = .downloaded
        } else {
            selectedRow = .all
        }
    }

    private func titleForRow(row: TableRow) -> String {
        switch row {
        case .all:
            return L10n.filterValueAll
        case .downloaded:
            return L10n.statusDownloaded
        case .notDownloaded:
            return L10n.statusNotDownloaded
        }
    }
}
