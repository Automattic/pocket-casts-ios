import PocketCastsUtils
import UIKit

class DownloadedFilesViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    private let switchCellId = "SwitchCell"
    private let checkboxCellId = "CheckboxSubtitleCellId"
    private let statsCellId = "StatsCell"
    private let buttonCellId = "ButtonCell"

    private var deleteUnplayed = false
    private var deletePlayed = true
    private var deleteInProgress = true
    private var includeStarred = true

    private var unplayedSize = 0 as UInt64
    private var playedSize = 0 as UInt64
    private var inProgressSize = 0 as UInt64

    @IBOutlet var settingsTable: UITableView! {
        didSet {
            settingsTable.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: switchCellId)
            settingsTable.register(UINib(nibName: "CheckboxSubtitleCell", bundle: nil), forCellReuseIdentifier: checkboxCellId)
            settingsTable.register(UINib(nibName: "StatsCell", bundle: nil), forCellReuseIdentifier: statsCellId)
            settingsTable.register(UINib(nibName: "DestructiveButtonCell", bundle: nil), forCellReuseIdentifier: buttonCellId)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.downloadedFiles
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: settingsTable)
        // load the last used values for cleanup
        deleteUnplayed = UserDefaults.standard.bool(forKey: Constants.UserDefaults.cleanupUnplayed)
        deletePlayed = UserDefaults.standard.bool(forKey: Constants.UserDefaults.cleanupPlayed)
        deleteInProgress = UserDefaults.standard.bool(forKey: Constants.UserDefaults.cleanupInProgress)
        includeStarred = UserDefaults.standard.bool(forKey: Constants.UserDefaults.cleanupStarred)

        reloadFileSizes()

        Analytics.track(.downloadsCleanUpShown)
    }

    // MARK: - UITableView Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 4 : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: checkboxCellId, for: indexPath) as! CheckboxSubtitleCell

            if indexPath.row == 0 {
                cell.titleLabel.text = L10n.statusUnplayed
                cell.setSelectedState(deleteUnplayed)
                cell.selectButton.removeTarget(self, action: #selector(DownloadedFilesViewController.unplayedToggled(_:)), for: .touchUpInside)
                cell.selectButton.addTarget(self, action: #selector(DownloadedFilesViewController.unplayedToggled(_:)), for: .touchUpInside)

                let sizeAsStr = SizeFormatter.shared.noDecimalFormat(bytes: Int64(unplayedSize))
                cell.subtitleLabel.text = sizeAsStr == "" ? SizeFormatter.shared.placeholder : sizeAsStr
            } else if indexPath.row == 1 {
                cell.titleLabel.text = L10n.inProgress
                cell.setSelectedState(deleteInProgress)
                cell.selectButton.removeTarget(self, action: #selector(DownloadedFilesViewController.inProgressToggled(_:)), for: .touchUpInside)
                cell.selectButton.addTarget(self, action: #selector(DownloadedFilesViewController.inProgressToggled(_:)), for: .touchUpInside)

                let sizeAsStr = SizeFormatter.shared.noDecimalFormat(bytes: Int64(inProgressSize))
                cell.subtitleLabel.text = sizeAsStr == "" ? SizeFormatter.shared.placeholder : sizeAsStr
            } else if indexPath.row == 2 {
                cell.titleLabel.text = L10n.statusPlayed
                cell.setSelectedState(deletePlayed)
                cell.selectButton.removeTarget(self, action: #selector(DownloadedFilesViewController.playedToggled(_:)), for: .touchUpInside)
                cell.selectButton.addTarget(self, action: #selector(DownloadedFilesViewController.playedToggled(_:)), for: .touchUpInside)

                let sizeAsStr = SizeFormatter.shared.noDecimalFormat(bytes: Int64(playedSize))
                cell.subtitleLabel.text = sizeAsStr == "" ? SizeFormatter.shared.placeholder : sizeAsStr
            } else if indexPath.row == 3 {
                cell.titleLabel.text = L10n.settingsStorageDownloadsStarred
                cell.setSelectedState(includeStarred)
                cell.selectButton.removeTarget(self, action: #selector(DownloadedFilesViewController.starredToggled(_:)), for: .touchUpInside)
                cell.selectButton.addTarget(self, action: #selector(DownloadedFilesViewController.starredToggled(_:)), for: .touchUpInside)
            }

            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: statsCellId, for: indexPath) as! StatsCell

            cell.statName.text = L10n.statsTotal
            cell.hideIcon()

            let total = totalDeleteSize()
            let sizeAsStr = SizeFormatter.shared.noDecimalFormat(bytes: Int64(total))
            cell.statValue.text = sizeAsStr == "" ? SizeFormatter.shared.placeholder : sizeAsStr

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: buttonCellId, for: indexPath) as! DestructiveButtonCell
            cell.buttonTitle.text = L10n.cleanUp
            cell.buttonTitle.textColor = canDeleteAnything() ? UIColor(hex: "#FC0000") : UIColor(hex: "#C8C8C8")

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 2, canDeleteAnything() {
            confirmCleanup()
        }
    }

    // MARK: - Switch Actions

    @objc private func unplayedToggled(_ sender: UIButton) {
        deleteUnplayed = !deleteUnplayed
        settingsTable.reloadData()
    }

    @objc private func playedToggled(_ sender: UIButton) {
        deletePlayed = !deletePlayed
        settingsTable.reloadData()
    }

    @objc private func inProgressToggled(_ sender: UIButton) {
        deleteInProgress = !deleteInProgress
        settingsTable.reloadData()
    }

    @objc private func starredToggled(_ sender: UIButton) {
        includeStarred = !includeStarred
        reloadFileSizes()
    }

    // MARK: - Private Helpers

    private func canDeleteAnything() -> Bool {
        totalDeleteSize() > 0 && (deleteUnplayed || deletePlayed || deleteInProgress)
    }

    private func confirmCleanup() {
        Analytics.track(.downloadsCleanUpButtonTapped)
        let confirmOption = OptionsPicker(title: nil)
        let deleteAction = OptionAction(label: L10n.delete, icon: nil) {
            self.performDelete()
        }
        deleteAction.destructive = true
        confirmOption.addDescriptiveActions(title: L10n.cleanUp, message: L10n.downloadedFilesCleanupConfirmation, icon: "option-delete", actions: [deleteAction])

        confirmOption.show(statusBarStyle: preferredStatusBarStyle)
    }

    private func performDelete() {
        // the user has chosen what to delete, so we should save that choice for next time
        UserDefaults.standard.set(deleteUnplayed, forKey: Constants.UserDefaults.cleanupUnplayed)
        UserDefaults.standard.set(deleteInProgress, forKey: Constants.UserDefaults.cleanupInProgress)
        UserDefaults.standard.set(deletePlayed, forKey: Constants.UserDefaults.cleanupPlayed)
        UserDefaults.standard.set(includeStarred, forKey: Constants.UserDefaults.cleanupStarred)

        Analytics.track(.downloadsCleanUpCompleted, properties: ["unplayed": deleteUnplayed, "in_progress": deleteInProgress, "played": deletePlayed, "include_starred": includeStarred])

        DispatchQueue.global(qos: .default).async { () in
            EpisodeManager.deleteAllDownloadedFiles(unplayed: self.deleteUnplayed, inProgress: self.deleteInProgress, played: self.deletePlayed, includeStarred: self.includeStarred)

            self.performRefresh()
        }
    }

    private func reloadFileSizes() {
        DispatchQueue.global(qos: .default).async { () in
            self.performRefresh()
        }
    }

    private func performRefresh() {
        unplayedSize = EpisodeManager.downloadSizeOfUnplayedEpisodes(includeStarred: includeStarred)
        inProgressSize = EpisodeManager.downloadSizeOfInProgressEpisodes(includeStarred: includeStarred)
        playedSize = EpisodeManager.downloadSizeOfPlayedEpisodes(includeStarred: includeStarred)

        DispatchQueue.main.async { () in
            self.settingsTable.reloadData()
        }
    }

    private func totalDeleteSize() -> UInt64 {
        var total = 0 as UInt64
        if deleteUnplayed { total += unplayedSize }
        if deleteInProgress { total += inProgressSize }
        if deletePlayed { total += playedSize }

        return total
    }
}
