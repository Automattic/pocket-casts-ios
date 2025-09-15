import PocketCastsDataModel
import UIKit
protocol FilterCreatedDelegate: AnyObject {
    func filterCreated(newFilter: EpisodeFilter)
}

class CreateFilterViewController: PCViewController, UITextFieldDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource {
    weak var delegate: FilterCreatedDelegate?

    @IBOutlet var tableView: UITableView!
    @IBOutlet var saveButton: ThemeableRoundedButton! {
        didSet {
            saveButton.backgroundColor = AppTheme.playlistBlueColor()
            saveButton.layer.cornerRadius = 12
            saveButton.setTitleColor(ThemeColor.primaryInteractive02(), for: .normal)
            saveButton.setTitle(L10n.filterCreateSave, for: .normal)
        }
    }

    var filterToEdit: EpisodeFilter
    private let iconChooserCellId = "IconChooserCellId"
    private let colorChooserCellId = "ColorChooserCell"
    private let textEntryCellId = "TextEntryCellId"
    private static let nameSection = 0
    private static let colorIconSection = 1

    private enum TableRow: Int { case filterName, color, icon }
    private static let tableData: [[TableRow]] = [[.filterName], [.color, .icon]]

    private var filterNameTextField: UITextField!

    init(filter: EpisodeFilter, delegate: FilterCreatedDelegate?) {
        filterToEdit = filter
        self.delegate = delegate
        super.init(nibName: "CreateFilterViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        colorChanged()
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.prefersLargeTitles = false
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        tableView.addGestureRecognizer(tapRecognizer)
        tableView.separatorStyle = .none
        tableView.backgroundColor = AppTheme.viewBackgroundColor()

        title = L10n.filterDetails
        tableView.register(UINib(nibName: "TextEntryCell", bundle: nil), forCellReuseIdentifier: textEntryCellId)

        tableView.register(UINib(nibName: "PlaylistIconChooserCell", bundle: nil), forCellReuseIdentifier: iconChooserCellId)
        tableView.register(UINib(nibName: "PlaylistColorChooserCell", bundle: nil), forCellReuseIdentifier: colorChooserCellId)

        NotificationCenter.default.addObserver(self, selector: #selector(colorChanged), name: Constants.Notifications.playlistTempChange, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        filterNameTextField?.becomeFirstResponder()
        colorChanged()
    }

    // MARK: - Tableivew Data source

    func numberOfSections(in tableView: UITableView) -> Int {
        CreateFilterViewController.tableData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        CreateFilterViewController.tableData[section].count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == CreateFilterViewController.nameSection {
            return 56
        }
        return 90
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = CreateFilterViewController.tableData[indexPath.section]
        let tableRow = section[indexPath.row]

        switch tableRow {
        case .filterName:
            let cell = tableView.dequeueReusableCell(withIdentifier: textEntryCellId) as! TextEntryCell
            filterNameTextField = cell.textField
            cell.textField.delegate = self
            cell.iconView.tintColor = filterToEdit.playlistColor()
            cell.style = .primaryUi01
            cell.borderView.style = .primaryField02
            return cell

        case .color:
            let cell = tableView.dequeueReusableCell(withIdentifier: colorChooserCellId) as! PlaylistColorChooserCell
            cell.playlist = filterToEdit
            cell.showSeperatorView()
            cell.style = .primaryUi01
            cell.accessibilityLabel = L10n.filterDetailsColorSelection
            return cell
        case .icon:
            let cell = tableView.dequeueReusableCell(withIdentifier: iconChooserCellId) as! PlaylistIconChooserCell
            cell.filterToEdit = filterToEdit
            cell.showSeperatorView()
            cell.style = .primaryUi01
            cell.setupWithTintColor(tintColor: filterToEdit.playlistColor(), selectedIcon: filterToEdit.customIcon, selectHandler: { selectedIcon in
                self.filterToEdit.customIcon = selectedIcon
                tableView.reloadData()
            })
            cell.accessibilityLabel = L10n.filterDetailsIconSelection
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Constants.Values.tableSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerFrame = CGRect(x: 0, y: 0, width: 0, height: 2 * Constants.Values.tableSectionHeaderHeight)
        let title: String

        switch section {
        case CreateFilterViewController.nameSection:
            title = L10n.filterDetailsName
        case CreateFilterViewController.colorIconSection:
            title = L10n.filterDetailsColorIcon
        default:
            return nil
        }

        let headerView = SettingsTableHeader(frame: headerFrame, title: title, themeStyle: .primaryUi01)
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        24
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        ThemeableView(frame: CGRect(x: 0, y: 0, width: 0, height: 24))
    }

    // MARK: Actions

    @IBAction func saveTapped(_ sender: Any) {
        filterToEdit.syncStatus = SyncStatus.notSynced.rawValue
        filterToEdit.isNew = false
        filterToEdit.setTitle(filterNameTextField.text, defaultTitle: L10n.filtersDefaultNewFilter.localizedCapitalized)
        DataManager.sharedManager.save(playlist: filterToEdit)
        UserDefaults.standard.set(filterToEdit.uuid, forKey: Constants.UserDefaults.lastFilterShown)
        delegate?.filterCreated(newFilter: filterToEdit)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: filterToEdit)
        dismiss(animated: true, completion: nil)

        Analytics.track(.filterCreated, properties: [
            "all_podcasts": filterToEdit.filterAllPodcasts,
            "media_type": AudioVideoFilter(rawValue: filterToEdit.filterAudioVideoType) ?? .all,
            "downloaded": filterToEdit.filterDownloaded,
            "not_downloaded": filterToEdit.filterNotDownloaded,
            "episode_status_played": filterToEdit.filterFinished,
            "episode_status_unplayed": filterToEdit.filterUnplayed,
            "episode_status_in_progress": filterToEdit.filterPartiallyPlayed,
            "release_date": ReleaseDateFilterOption(rawValue: filterToEdit.filterHours) ?? .anytime,
            "starred": filterToEdit.filterStarred,
            "duration": filterToEdit.filterDuration,
            "duration_longer_than": filterToEdit.longerThan,
            "duration_shorter_than": filterToEdit.shorterThan,
            "color": filterToEdit.playlistColor().hexString(),
            "icon_name": filterToEdit.iconImageName() ?? "unknown"
        ])
    }

    @objc func backgroundTapped(_ sender: UITapGestureRecognizer) {
        if let nameTextField = filterNameTextField {
            if nameTextField.isFirstResponder {
                nameTextField.resignFirstResponder()
            }
        }
    }

    @IBAction func closeTapped(sender: Any) {
        PlaylistManager.delete(playlist: filterToEdit, fireEvent: true)
        dismiss(animated: true, completion: nil)
    }

    @objc func colorChanged() {
        tableView.reloadData()
        saveButton.backgroundColor = filterToEdit.playlistColor()
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let filterNameTextField = filterNameTextField else { return }

        // dismiss the keyboard on scroll up
        if scrollView.contentOffset.y > 40, filterNameTextField.isFirstResponder {
            filterNameTextField.resignFirstResponder()
        }
    }

    // MARK: - TextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidStart)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidEnd)
        textField.resignFirstResponder()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }

    override func handleThemeChanged() {
        saveButton.backgroundColor = filterToEdit.playlistColor()
        tableView.backgroundColor = AppTheme.viewBackgroundColor()
        colorChanged()
    }
}
