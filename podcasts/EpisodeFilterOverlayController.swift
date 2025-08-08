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

        if FeatureFlag.playlistsRebranding.enabled {
            handleThemeChanged()

            saveButton.setTitle(L10n.playlistSmartRuleSaveButton, for: .normal)
        }
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
        if FeatureFlag.playlistsRebranding.enabled {
            cell.episodeTitle.font = .systemFont(ofSize: 18, weight: .semibold)
            cell.filterColor = AppTheme.colorForStyle(.primaryInteractive01)
        } else {
            cell.episodeTitle.font = .systemFont(ofSize: 16, weight: .medium)
            cell.filterColor = filterToEdit.playlistColor()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        FeatureFlag.playlistsRebranding.enabled ? 48 : 51
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
            if FeatureFlag.playlistsRebranding.enabled {
                saveButton.alpha = 1
            } else {
                saveButton.backgroundColor = filterToEdit.playlistColor()
            }
        } else {
            saveButton.isEnabled = false
            if FeatureFlag.playlistsRebranding.enabled {
                saveButton.alpha = 0.4
            } else {
                saveButton.backgroundColor = AppTheme.disabledButtonColor()
            }
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

    override func handleThemeChanged() {
        super.handleThemeChanged()

        if FeatureFlag.playlistsRebranding.enabled {
            saveButton.backgroundColor = AppTheme.colorForStyle(.primaryInteractive01)
            changeNavTint(titleColor: nil, iconsColor: AppTheme.colorForStyle(.primaryIcon03))
        }
    }
}
