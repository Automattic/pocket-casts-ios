import UIKit
import PocketCastsUtils

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
        if FeatureFlag.playlistsRebranding.enabled {
            largeTitleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        }
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

        if FeatureFlag.playlistsRebranding.enabled {
            navigationItem.largeTitleDisplayMode = .always

            handleThemeChanged()

            saveButton.setTitle(L10n.playlistSmartRuleSaveButton, for: .normal)
        } else {
            addCloseButton()
        }
    }

    override func addTableViewHeader() {
        let headerView = ThemeableView()
        headerView.style = .primaryUi01
        if FeatureFlag.playlistsRebranding.enabled {
            headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 10)
        } else {
            headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 26)
        }
        headerView.layoutIfNeeded()
        tableView.tableHeaderView = headerView
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
        if FeatureFlag.playlistsRebranding.enabled {
            cell.title.font = .systemFont(ofSize: 17, weight: .semibold)
            cell.setTintColor(color: AppTheme.colorForStyle(.primaryInteractive01))
        } else {
            cell.title.font = .systemFont(ofSize: 16, weight: .medium)
            cell.setTintColor(color: filterToEdit.playlistColor())
        }
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
        FeatureFlag.playlistsRebranding.enabled ? 46 : 51
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
        if FeatureFlag.playlistsRebranding.enabled {
            filterToEdit.downloadStatusSmartRuleApplied = true
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

    override func handleThemeChanged() {
        super.handleThemeChanged()

        if FeatureFlag.playlistsRebranding.enabled {
            saveButton.backgroundColor = AppTheme.colorForStyle(.primaryInteractive01)
            changeNavTint(titleColor: AppTheme.colorForStyle(.primaryText01), iconsColor: AppTheme.colorForStyle(.primaryIcon03), backgroundColor: AppTheme.viewBackgroundColor())
        }
    }

    override func dismissViewController() {
        if FeatureFlag.playlistsRebranding.enabled {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}
