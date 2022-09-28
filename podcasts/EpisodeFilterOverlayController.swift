import UIKit

class EpisodeFilterOverlayController: FilterSettingsOverlayController, UITableViewDataSource, UITableViewDelegate {
    static let episodeCellId = "CheckboxCellId"

    private enum TableRow: Int { case unplayed, inProgress, played }
    private static let tableData: [[TableRow]] = [[.unplayed, .inProgress, .played]]

    private var filterUnplayed: Bool!
    private var filterPartiallyPlayed: Bool!
    private var filterFinished: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "CheckboxCell", bundle: nil), forCellReuseIdentifier: EpisodeFilterOverlayController.episodeCellId)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        addTableViewHeader()

        setupLargeTitle()
        title = L10n.filterEpisodeStatus
        tableView.contentInsetAdjustmentBehavior = .never

        setCurrentStatus()

        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        addCloseButton()
    }

    // MARK: - TableView DataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        EpisodeFilterOverlayController.tableData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        EpisodeFilterOverlayController.tableData[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EpisodeFilterOverlayController.episodeCellId, for: indexPath) as! CheckboxCell

        let tableRow = EpisodeFilterOverlayController.tableData[indexPath.section][indexPath.row]

        switch tableRow {
        case .unplayed:
            cell.episodeTitle.text = L10n.statusUnplayed
            cell.setSelectedState(filterUnplayed)
        case .inProgress:
            cell.episodeTitle.text = L10n.inProgress
            cell.setSelectedState(filterPartiallyPlayed)
        case .played:
            cell.episodeTitle.text = L10n.statusPlayed
            cell.setSelectedState(filterFinished)
        }
        cell.style = .primaryUi01
        cell.episodeTitle.setLetterSpacing(-0.2)
        cell.selectButton.tag = tableRow.rawValue
        cell.selectButton.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
        cell.filterColor = filterToEdit.playlistColor()
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        51
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! CheckboxCell
        selectButtonTapped(cell.selectButton)
    }

    // MARK: - Actions

    @objc func selectButtonTapped(_ sender: AnyObject) {
        guard let tag = sender.tag else { return }

        guard let tableRow = EpisodeFilterOverlayController.TableRow(rawValue: tag) else { return }
        switch tableRow {
        case .unplayed:
            filterUnplayed = !filterUnplayed
        case .inProgress:
            filterPartiallyPlayed = !filterPartiallyPlayed
        case .played:
            filterFinished = !filterFinished
        }

        if filterFinished || filterUnplayed || filterPartiallyPlayed {
            saveButton.isEnabled = true
            saveButton.backgroundColor = filterToEdit.playlistColor()
        } else {
            saveButton.isEnabled = false
            saveButton.backgroundColor = AppTheme.disabledButtonColor()
        }
        tableView.reloadData()
    }

    private func setCurrentStatus() {
        filterFinished = filterToEdit.filterFinished
        filterUnplayed = filterToEdit.filterUnplayed
        filterPartiallyPlayed = filterToEdit.filterPartiallyPlayed
    }

    override func saveFilter() {
        filterToEdit.filterFinished = filterFinished
        filterToEdit.filterUnplayed = filterUnplayed
        filterToEdit.filterPartiallyPlayed = filterPartiallyPlayed

        super.saveFilter()
    }
}
