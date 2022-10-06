import UIKit

enum ReleaseDateFilterOption: Int32, AnalyticsDescribable {
    case anytime = 0
    case last24hours = 24
    case last3Days = 72
    case lastWeek = 168
    case last2Weeks = 336
    case lastMonth = 744

    var description: String {
        switch self {
        case .anytime:
            return L10n.filterReleaseDateAnytime
        case .last24hours:
            return L10n.filterReleaseDateLast24Hours
        case .last3Days:
            return L10n.filterReleaseDateLast3Days
        case .lastWeek:
            return L10n.filterReleaseDateLastWeek
        case .last2Weeks:
            return L10n.filterReleaseDateLast2Weeks
        case .lastMonth:
            return L10n.filterReleaseDateLastMonth
        }
    }

    var analyticsDescription: String {
        switch self {
        case .anytime:
            return "anytime"
        case .last24hours:
            return "24_hours"
        case .last3Days:
            return "3_days"
        case .lastWeek:
            return "last_week"
        case .last2Weeks:
            return "last_2_weeks"
        case .lastMonth:
            return "last_month"
        }
    }
}

class ReleaseDateFilterOverlayController: FilterSettingsOverlayController, UITableViewDataSource, UITableViewDelegate {
    private static let releaseCellId = "RadioButtonCellId"
    let choices: [ReleaseDateFilterOption] = [.anytime, .last24hours, .last3Days, .lastWeek, .last2Weeks, .lastMonth]
    var selectedIndex = 0

    override var analyticsSource: AnalyticsSource {
        .releaseDate
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "RadioButtonCell", bundle: nil), forCellReuseIdentifier: ReleaseDateFilterOverlayController.releaseCellId)

        setCurrentReleaseDate()
        setupLargeTitle()
        title = L10n.filterReleaseDate
        tableView.contentInsetAdjustmentBehavior = .never

        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        addCloseButton()
        addTableViewHeader()
    }

    // MARK: - TableView DataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        choices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReleaseDateFilterOverlayController.releaseCellId) as! RadioButtonCell
        cell.title.text = choices[indexPath.row].description
        cell.title.setLetterSpacing(-0.2)
        cell.style = .primaryUi01
        cell.setSelectState(selectedIndex == indexPath.row)
        let filterTintColor = filterToEdit.playlistColor()
        cell.setTintColor(color: filterTintColor)
        cell.selectButton.tag = indexPath.row
        cell.selectButton.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        51
    }

    // MARK: - Helper functions

    func setCurrentReleaseDate() {
        for (index, element) in choices.enumerated() {
            if filterToEdit.filterHours <= element.rawValue {
                selectedIndex = index
                break
            }
        }
    }

    override func saveFilter() {
        filterToEdit.filterHours = choices[selectedIndex].rawValue
        super.saveFilter()
    }

    @objc func selectButtonTapped(_ sender: AnyObject) {
        guard let buttonTag = sender.tag else { return }

        selectedIndex = buttonTag
        tableView.reloadData()
    }
}
