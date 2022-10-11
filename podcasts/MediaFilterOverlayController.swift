import PocketCastsDataModel
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

        tableView.delegate = self
        tableView.dataSource = self

        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "RadioButtonCell", bundle: nil), forCellReuseIdentifier: MediaFilterOverlayController.mediaCellId)

        setupLargeTitle()
        title = L10n.filterMediaType
        tableView.contentInsetAdjustmentBehavior = .never
        selectedIndex = Int(filterToEdit.filterAudioVideoType)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: MediaFilterOverlayController.mediaCellId) as! RadioButtonCell
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

    override func saveFilter() {
        filterToEdit.filterAudioVideoType = Int32(selectedIndex)
        super.saveFilter()
    }

    @objc func selectButtonTapped(_ sender: AnyObject) {
        guard let buttonTag = sender.tag else { return }

        selectedIndex = buttonTag
        tableView.reloadData()
    }
}
