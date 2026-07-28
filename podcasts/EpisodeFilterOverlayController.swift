import UIKit
import PocketCastsUtils

class EpisodeFilterOverlayController: FilterSettingsOverlayController, UITableViewDataSource, UITableViewDelegate {
    static let episodeCellId = "CheckboxCellId"

    private enum TableRow: Int { case unplayed, inProgress, played }
    private static let tableData: [[TableRow]] = [[.unplayed, .inProgress, .played]]

    private var filterUnplayed: Bool!
    private var filterPartiallyPlayed: Bool!
    private var filterFinished: Bool!

    override var analyticsSource: AnalyticsSource {
        .episodeStatus
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        largeTitleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        tableView.register(UINib(nibName: "CheckboxCell", bundle: nil), forCellReuseIdentifier: EpisodeFilterOverlayController.episodeCellId)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        addTableViewHeader()
        title = SmartPlaylistRule.episode.title
        setupLargeTitle()
        tableView.contentInsetAdjustmentBehavior = .never

        setCurrentStatus()

        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        navigationItem.largeTitleDisplayMode = .always

        handleThemeChanged()

        saveButton.setTitle(L10n.playlistSmartRuleSaveButton, for: .normal)
    }

    override func addTableViewHeader() {
        let headerView = ThemeableView()
        headerView.style = .primaryUi01
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 10)
        headerView.layoutIfNeeded()
        tableView.tableHeaderView = headerView
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
        cell.episodeTitle.font = .font(ofSize: 17, weight: .semibold, scalingWith: .body)
        cell.filterColor = AppTheme.colorForStyle(.primaryInteractive01)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        48
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
            saveButton.alpha = 1
        } else {
            saveButton.isEnabled = false
            saveButton.alpha = 0.4
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
        filterToEdit.episodesSmartRuleApplied = true
        super.saveFilter()
    }

    override func handleThemeChanged() {
        super.handleThemeChanged()

        saveButton.backgroundColor = AppTheme.colorForStyle(.primaryInteractive01)
        changeNavTint(titleColor: AppTheme.colorForStyle(.primaryText01), iconsColor: AppTheme.colorForStyle(.primaryIcon03), backgroundColor: AppTheme.viewBackgroundColor())
    }

    override func dismissViewController() {
        navigationController?.popViewController(animated: true)
    }
}
