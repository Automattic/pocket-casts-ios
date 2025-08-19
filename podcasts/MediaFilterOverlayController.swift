import PocketCastsDataModel
import PocketCastsUtils
import UIKit

extension AudioVideoFilter {
    var description: String {
        switch self {
        case .all:
            return L10n.filterValueAll
        case .audioOnly:
            return L10n.filterMediaTypeAudio
        case .videoOnly:
            return L10n.filterMediaTypeVideo
        }
    }
}

class MediaFilterOverlayController: FilterSettingsOverlayController, UITableViewDataSource, UITableViewDelegate {
    private static let mediaCellId = "RadioButtonCellId"
    let choices: [AudioVideoFilter] = [.all, .audioOnly, .videoOnly]

    var selectedIndex = 0

    override var analyticsSource: AnalyticsSource {
        .mediaType
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if FeatureFlag.playlistsRebranding.enabled {
            largeTitleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        }
        tableView.delegate = self
        tableView.dataSource = self

        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "RadioButtonCell", bundle: nil), forCellReuseIdentifier: MediaFilterOverlayController.mediaCellId)

        setupLargeTitle()
        title = L10n.filterMediaType
        tableView.contentInsetAdjustmentBehavior = .never
        selectedIndex = Int(filterToEdit.filterAudioVideoType)
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        if !FeatureFlag.playlistsRebranding.enabled {
            addCloseButton()
        }
        addTableViewHeader()

        if FeatureFlag.playlistsRebranding.enabled {
            navigationItem.largeTitleDisplayMode = .always

            handleThemeChanged()

            saveButton.setTitle(L10n.playlistSmartRuleSaveButton, for: .normal)
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
        choices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MediaFilterOverlayController.mediaCellId) as! RadioButtonCell
        cell.title.text = choices[indexPath.row].description
        cell.title.setLetterSpacing(-0.2)
        cell.style = .primaryUi01
        cell.setSelectState(selectedIndex == indexPath.row)
        if FeatureFlag.playlistsRebranding.enabled {
            cell.title.font = .systemFont(ofSize: 17, weight: .semibold)
            cell.setTintColor(color: AppTheme.colorForStyle(.primaryInteractive01))
        } else {
            cell.title.font = .systemFont(ofSize: 16, weight: .medium)
            cell.setTintColor(color: filterToEdit.playlistColor())
        }
        cell.selectButton.tag = indexPath.row
        cell.selectButton.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        FeatureFlag.playlistsRebranding.enabled ? 46 : 51
    }

    // MARK: - Helper functions

    override func saveFilter() {
        filterToEdit.filterAudioVideoType = Int32(selectedIndex)
        if FeatureFlag.playlistsRebranding.enabled {
            filterToEdit.mediaTypeSmartRuleApplied = true
        }
        super.saveFilter()
    }

    @objc func selectButtonTapped(_ sender: AnyObject) {
        guard let buttonTag = sender.tag else { return }

        selectedIndex = buttonTag
        tableView.reloadData()
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
