import UIKit

class AutoArchiveViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    private let settingsSection = 0
    private let starredSection = 1

    private let switchCellId = "SwitchCell"
    private let disclosureCellId = "DisclosureCell"

    @IBOutlet var archiveTable: UITableView! {
        didSet {
            archiveTable.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: switchCellId)
            archiveTable.register(UINib(nibName: "DisclosureCell", bundle: nil), forCellReuseIdentifier: disclosureCellId)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsAutoArchive
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        archiveTable.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == settingsSection ? 2 : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == starredSection {
            return tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath)
        }

        return tableView.dequeueReusableCell(withIdentifier: disclosureCellId, for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == settingsSection {
            let castCell = cell as! DisclosureCell
            if indexPath.row == 0 {
                castCell.cellLabel.text = L10n.settingsArchivePlayedEpisodes
                castCell.cellSecondaryLabel.text = ArchiveHelper.archiveTimeToText(Settings.autoArchivePlayedAfter())
            } else if indexPath.row == 1 {
                castCell.cellLabel.text = L10n.settingsArchiveInactiveEpisodes
                castCell.cellSecondaryLabel.text = ArchiveHelper.archiveTimeToText(Settings.autoArchiveInactiveAfter())
            }
        } else if indexPath.section == starredSection {
            let castCell = cell as! SwitchCell
            castCell.cellLabel.text = L10n.settingsAutoArchiveIncludeStarred
            castCell.cellSwitch.isOn = Settings.archiveStarredEpisodes()

            castCell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            castCell.cellSwitch.addTarget(self, action: #selector(archiveStarredChanged(_:)), for: UIControl.Event.valueChanged)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == settingsSection {
            if indexPath.row == 0 {
                let options = OptionsPicker(title: L10n.settingsArchivePlayedTitle)

                addArchivePlayedAction(time: -1, to: options)
                addArchivePlayedAction(time: 0, to: options)
                addArchivePlayedAction(time: 24.hours, to: options)
                addArchivePlayedAction(time: 2.days, to: options)
                addArchivePlayedAction(time: 1.week, to: options)

                options.show(statusBarStyle: preferredStatusBarStyle)
            } else if indexPath.row == 1 {
                let options = OptionsPicker(title: L10n.settingsArchiveInactiveTitle)

                addArchiveInactiveAction(time: -1, to: options)
                addArchiveInactiveAction(time: 1.week, to: options)
                addArchiveInactiveAction(time: 2.weeks, to: options)
                addArchiveInactiveAction(time: 30.days, to: options)
                addArchiveInactiveAction(time: 90.days, to: options)

                options.show(statusBarStyle: preferredStatusBarStyle)
            }
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerFrame = CGRect(x: 0, y: 0, width: 0, height: Constants.Values.tableSectionHeaderHeight)

        return section == starredSection ? SettingsTableHeader(frame: headerFrame, title: L10n.settings.localizedUppercase) : nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Constants.Values.tableSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == settingsSection {
            return L10n.settingsAutoArchiveSubtitle
        } else if section == starredSection {
            return Settings.archiveStarredEpisodes() ? L10n.settingsAutoArchiveIncludeStarredOnSubtitle : L10n.settingsAutoArchiveIncludeStarredOffSubtitle
        }

        return nil
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }

    private func addArchivePlayedAction(time: TimeInterval, to: OptionsPicker) {
        let selectedSetting = Settings.autoArchivePlayedAfter()
        let action = OptionAction(label: ArchiveHelper.archiveTimeToText(time), selected: selectedSetting == time) { [weak self] in
            Settings.setAutoArchivePlayedAfter(time)
            self?.archiveTable.reloadData()
        }
        to.addAction(action: action)
    }

    private func addArchiveInactiveAction(time: TimeInterval, to: OptionsPicker) {
        let selectedSetting = Settings.autoArchiveInactiveAfter()
        let action = OptionAction(label: ArchiveHelper.archiveTimeToText(time), selected: selectedSetting == time) { [weak self] in
            Settings.setAutoArchiveInactiveAfter(time)
            self?.archiveTable.reloadData()
        }
        to.addAction(action: action)
    }

    @objc private func archiveStarredChanged(_ sender: UISwitch) {
        Settings.setArchiveStarredEpisodes(sender.isOn)

        archiveTable.beginUpdates()
        if let containerView = archiveTable.footerView(forSection: starredSection) {
            containerView.textLabel?.text = tableView(archiveTable, titleForFooterInSection: starredSection)
            containerView.sizeToFit()
        }
        archiveTable.endUpdates()
    }
}
