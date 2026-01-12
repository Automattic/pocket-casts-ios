import IntentsUI
import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class PlaylistShortcutsViewController: PCViewController, UITableViewDelegate, UITableViewDataSource, INUIAddVoiceShortcutViewControllerDelegate, INUIEditVoiceShortcutViewControllerDelegate {
    @IBOutlet var tableView: ThemeableTable!
    @IBOutlet var errorView: UIStackView!

    var playlist: EpisodeFilter!
    weak var delegate: SiriSettingsViewController?

    let enabledCellId = "siriEnabledCellId"
    let suggestedCellId = "siriSuggestedCellId"

    enum sections { case enabledSection, availableSection }
    var tableData: [sections] = []
    enum tableRow { case playTopEpisode, playAll, openPlaylist }
    var availableRows: [tableRow] = [.playTopEpisode, .playAll, .openPlaylist]

    var enabledShortcuts: [INVoiceShortcut]!

    @IBOutlet var activityIndicator: ThemeLoadingIndicator!

    init(playlist: EpisodeFilter) {
        self.playlist = playlist
        super.init(nibName: "PlaylistShortcutsViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.settingsSiriShortcuts
        view.backgroundColor = AppTheme.colorForStyle(.primaryUi04)

        tableView.register(UINib(nibName: "SiriShortcutEnabledCell", bundle: nil), forCellReuseIdentifier: enabledCellId)
        tableView.register(UINib(nibName: "SiriShortcutSuggestedCell", bundle: nil), forCellReuseIdentifier: suggestedCellId)

        track(.filterSiriShortcutsShown)
    }

    override func viewDidAppear(_ animated: Bool) {
        getEnabledShortcuts()
    }

    override func handleThemeChanged() {
        view.backgroundColor = AppTheme.colorForStyle(.primaryUi04)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        tableData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = tableData[section]
        switch section {
        case .enabledSection:
            return enabledShortcuts.count
        case .availableSection:
            return availableRows.count
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerFrame = CGRect(x: 0, y: 0, width: 0, height: Constants.Values.tableSectionHeaderHeight)
        let thisSection = tableData[section]
        switch thisSection {
        case .enabledSection:
            return SettingsTableHeader(frame: headerFrame, title: L10n.settingsSiriShortcutsEnabled)
        case .availableSection:
            return SettingsTableHeader(frame: headerFrame, title: L10n.settingsSiriShortcutsAvailable)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Constants.Values.tableSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = tableData[indexPath.section]
        switch section {
        case .enabledSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: enabledCellId) as! SiriShortcutEnabledCell
            let voiceshortcut = enabledShortcuts[indexPath.row]
            cell.phraseLabel.text = "\"\(voiceshortcut.invocationPhrase)\""
            if let intent = voiceshortcut.shortcut.intent {
                cell.titleLabel?.text = intent.suggestedInvocationPhrase
            }
            return cell
        case .availableSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: suggestedCellId) as! SiriShortcutSuggestedCell
            if let thisRow = availableRows[safe: indexPath.row] {
                switch thisRow {
                case .playAll:
                    cell.titleLabel?.text = L10n.settingsShortcutsFilterPlayAllEpisodes
                case .playTopEpisode:
                    cell.titleLabel?.text = L10n.settingsShortcutsFilterPlayTopEpisode
                case .openPlaylist:
                    cell.titleLabel?.text = FeatureFlag.playlistsRebranding.enabled ? L10n.settingsShortcutsFilterOpenPlaylist : L10n.settingsShortcutsFilterOpenFilter
                }
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        64
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = tableData[indexPath.section]

        switch section {
        case .enabledSection:
            let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: enabledShortcuts[indexPath.row])
            viewController.modalPresentationStyle = .formSheet
            viewController.delegate = self
            present(viewController, animated: true, completion: nil)
        case .availableSection:
            let thisRow = availableRows[indexPath.row]
            var newShortcut: INShortcut
            switch thisRow {
            case .playTopEpisode:
                newShortcut = SiriShortcutsManager.shared.playPlaylistShortcut(playlist: playlist)
            case .playAll:
                newShortcut = SiriShortcutsManager.shared.playAllPlaylistShortcut(playlist: playlist)
            case .openPlaylist:
                newShortcut = SiriShortcutsManager.shared.openPlaylistShortcut(playlist: playlist)
            }

            let viewController = INUIAddVoiceShortcutViewController(shortcut: newShortcut)
            viewController.modalPresentationStyle = .formSheet
            viewController.delegate = self
            present(viewController, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }

    // Helper functions
    private func getEnabledShortcuts() {
        errorView.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { allVoiceShortcuts, error in
            self.enabledShortcuts = []
            self.availableRows = [.playTopEpisode, .playAll, .openPlaylist]

            if let allVoiceShortcuts = allVoiceShortcuts {
                for voiceShortcut in allVoiceShortcuts {
                    if let playIntent = voiceShortcut.shortcut.intent as? INPlayMediaIntent {
                        if playIntent.mediaContainer?.identifier == self.playlist.uuid {
                            self.enabledShortcuts.append(voiceShortcut)
                            if let mediaItem = playIntent.mediaItems?.first {
                                if mediaItem.identifier == Constants.SiriActions.playFilterId {
                                    if let removeIndex = self.availableRows.firstIndex(of: .playTopEpisode) {
                                        self.availableRows.remove(at: removeIndex)
                                    }
                                } else if mediaItem.identifier == Constants.SiriActions.playAllFilterId {
                                    if let removeIndex = self.availableRows.firstIndex(of: .playAll) {
                                        self.availableRows.remove(at: removeIndex)
                                    }
                                }
                            }
                        }
                    } else if let openFilterIntent = voiceShortcut.shortcut.intent as? SJOpenFilterIntent {
                        if openFilterIntent.filterUuid == self.playlist.uuid {
                            self.enabledShortcuts.append(voiceShortcut)
                            if let removeIndex = self.availableRows.firstIndex(of: .openPlaylist) {
                                self.availableRows.remove(at: removeIndex)
                            }
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                if let error = error {
                    FileLog.shared.addMessage("Failed INVoiceShortcutCenter.getAllVoiceShortcuts with error \(error.localizedDescription)")
                    self.errorView.isHidden = false
                } else {
                    self.reloadData()
                }
            }
        }
    }

    func enabledSection() -> Int {
        enabledShortcuts.count > 0 ? 0 : -1
    }

    func availableSection() -> Int {
        if enabledSection() == 0 {
            return availableRows.count > 0 ? 1 : -1
        }
        return 0
    }

    private func reloadData() {
        tableData = []
        if enabledShortcuts.count > 0 {
            tableData.append(.enabledSection)
        }
        if availableRows.count > 0 {
            tableData.append(.availableSection)
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // MARK: INUIAddVoiceShortcutViewController

    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        getEnabledShortcuts()
        reloadData()
        controller.dismiss(animated: true, completion: nil)
        track(.filterSiriShortcutAdded)
    }

    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    // MARK: INUIEditVoiceShortcutViewControllerDelegate

    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        getEnabledShortcuts()
        reloadData()
        controller.dismiss(animated: true, completion: nil)
    }

    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        getEnabledShortcuts()
        reloadData()
        controller.dismiss(animated: true, completion: nil)
        track(.filterSiriShortcutRemoved)
    }

    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    @IBAction func tryAgainTapped() {
        getEnabledShortcuts()
    }
}

extension PlaylistShortcutsViewController: PlaylistTypeTrackerProvider {
    var analyticsSourceType: String {
        playlist.manual ? "manual" : "smart"
    }
}
