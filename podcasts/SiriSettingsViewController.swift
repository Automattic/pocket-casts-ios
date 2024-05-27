import IntentsUI
import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class SiriSettingsViewController: PCViewController, UITableViewDelegate, UITableViewDataSource, INUIAddVoiceShortcutViewControllerDelegate, INUIEditVoiceShortcutViewControllerDelegate {
    @IBOutlet var tableView: UITableView! {
        didSet {
            tableView.register(UINib(nibName: "SiriShortcutEnabledCell", bundle: nil), forCellReuseIdentifier: enabledCellId)
            tableView.register(UINib(nibName: "SiriShortcutSuggestedCell", bundle: nil), forCellReuseIdentifier: suggestedCellId)
            tableView.register(UINib(nibName: "SiriShortcutDisclosureCell", bundle: nil), forCellReuseIdentifier: disclosureCelld)
        }
    }

    @IBOutlet var activityIndicator: ThemeLoadingIndicator!
    @IBOutlet var errorView: UIStackView!
    var suggestedShortcuts: [INShortcut]!
    var enabledShortcuts: [INVoiceShortcut]!

    private enum sections { case enabledSection, suggestedSection, playSection }
    private var tableData: [sections] = []
    private enum playRow { case playPodcast, playFilter }
    private var playRows: [playRow] = [.playPodcast, .playFilter]

    let enabledCellId = "siriEnabledCellId"
    let suggestedCellId = "siriSuggestedCellId"
    let disclosureCelld = "siriDisclosureCellId"
    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.settingsSiriShortcuts
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        suggestedShortcuts = SiriShortcutsManager.shared.defaultSuggestions()
        enabledShortcuts = [INVoiceShortcut]()
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: tableView)
        Analytics.track(.settingsSiriShown)
    }

    override func viewDidAppear(_ animated: Bool) {
        getEnabledShortcuts()
    }

    // MARK: Tableview delegate and datasource

    func numberOfSections(in tableView: UITableView) -> Int {
        tableData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = tableData[section]
        switch section {
        case .enabledSection:
            return enabledShortcuts.count
        case .suggestedSection:
            return suggestedShortcuts.count
        case .playSection:
            return playRows.count
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerFrame = CGRect(x: 0, y: 0, width: 0, height: Constants.Values.tableSectionHeaderHeight)

        let section = tableData[section]
        switch section {
        case .enabledSection:
            return SettingsTableHeader(frame: headerFrame, title: L10n.settingsSiriShortcutsEnabled.localizedCapitalized)
        case .suggestedSection:
            return SettingsTableHeader(frame: headerFrame, title: L10n.settingsSiriShortcutsAvailable.localizedCapitalized)
        case .playSection:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Constants.Values.tableSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        64
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
        case .suggestedSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: suggestedCellId) as! SiriShortcutSuggestedCell
            let shortcut = suggestedShortcuts[indexPath.row]
            if let intent = shortcut.intent {
                cell.titleLabel?.text = intent.suggestedInvocationPhrase
            }
            return cell
        case .playSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCelld) as! SiriShortcutDisclosureCell
            let row = playRows[indexPath.row]
            switch row {
            case .playPodcast:
                cell.titleLabel?.text = L10n.settingsSiriShortcutsSpecificPodcast
            case .playFilter:
                cell.titleLabel?.text = L10n.settingsSiriShortcutsSpecificFilter
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = tableData[indexPath.section]

        switch section {
        case .enabledSection:
            let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: enabledShortcuts[indexPath.row])
            viewController.modalPresentationStyle = .formSheet
            viewController.delegate = self
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
            present(viewController, animated: true, completion: nil)

        case .suggestedSection:
            let viewController = INUIAddVoiceShortcutViewController(shortcut: suggestedShortcuts[indexPath.row])
            viewController.modalPresentationStyle = .formSheet
            viewController.delegate = self
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
            present(viewController, animated: true, completion: nil)
        case .playSection:
            let row = playRows[indexPath.row]
            switch row {
            case .playFilter:
                showFiltersShortcutsViewController()
            case .playPodcast:
                showPodcastShortcutsViewController()
            }
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }

    private func showPodcastShortcutsViewController() {
        let viewController = PodcastShortcutsViewController()
        var podcasts = DataManager.sharedManager.allPodcastsOrderedByTitle()
        for podcast in podcasts {
            for existingShortcut in enabledShortcuts {
                guard existingShortcut.shortcut.intent is INPlayMediaIntent else { continue }
                let playMediaIntent = existingShortcut.shortcut.intent as! INPlayMediaIntent
                if playMediaIntent.mediaContainer?.identifier == podcast.uuid {
                    if let index = podcasts.firstIndex(of: podcast) {
                        podcasts.remove(at: index)
                    }
                }
            }
        }
        viewController.podcasts = podcasts
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func showFiltersShortcutsViewController() {
        let viewController = FiltersShortcutsViewController()
        let filters = DataManager.sharedManager.allFilters(includeDeleted: false)
        viewController.filters = filters
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: - Editing

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        false
    }

    // MARK: - helper functions

    private func reloadData() {
        var newSections = [sections]()
        if enabledShortcuts.count > 0 {
            newSections.append(.enabledSection)
        }

        if suggestedShortcuts.count > 0 {
            newSections.append(.suggestedSection)
        }

        newSections.append(.playSection)
        tableData = newSections
        tableView.reloadData()
    }

    private func getEnabledShortcuts() {
        errorView.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { allVoiceShortcuts, error in

            if allVoiceShortcuts != nil, error == nil {
                self.enabledShortcuts = allVoiceShortcuts
                for voiceShortcut in self.enabledShortcuts {
                    if SiriShortcutsManager.shared.isDefaultSuggestion(voiceShortcut: voiceShortcut) {
                        self.suggestedShortcuts.removeAll(where: { $0.intent?.suggestedInvocationPhrase == voiceShortcut.shortcut.intent?.suggestedInvocationPhrase })
                    }
                }
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.reloadData()
                    self.errorView.isHidden = true
                }
            } else {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.errorView.isHidden = false
                }
                if let error = error {
                    FileLog.shared.addMessage("Failed INVoiceShortcutCenter.getAllVoiceShortcuts with error \(error.localizedDescription)")
                }
            }
        }
    }

    private func deleteEnabledShortcut(voiceShortcut: INVoiceShortcut) {
        if SiriShortcutsManager.shared.isDefaultSuggestion(voiceShortcut: voiceShortcut) {
            if let chapterIntent = voiceShortcut.shortcut.intent as? SJChapterIntent {
                // the following is a special case as we replace SJChapterIntent with a INPlayMediaIntent in v7.8.1
                if chapterIntent.skipForward == .next {
                    suggestedShortcuts.append(SiriShortcutsManager.shared.nextChapterShortcut())
                } else {
                    suggestedShortcuts.append(SiriShortcutsManager.shared.previousChapterShortcut())
                }
            } else {
                suggestedShortcuts.append(voiceShortcut.shortcut)
            }
        }
        if let index = enabledShortcuts.firstIndex(of: voiceShortcut) {
            enabledShortcuts.remove(at: index)
        }
        reloadData()
    }

    func voiceShortcutForShortcut(shortcut: INShortcut) -> INVoiceShortcut? {
        guard let existingShortcuts = enabledShortcuts else { return nil }
        for voice in existingShortcuts {
            if voice.shortcut == shortcut {
                return voice
            }
        }
        return nil
    }

    // MARK: INUIAddVoiceShortcutViewController

    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        if let voiceShortcut = voiceShortcut {
            enabledShortcuts.append(voiceShortcut)
            if let index = suggestedShortcuts.firstIndex(of: voiceShortcut.shortcut) {
                suggestedShortcuts.remove(at: index)
            }
        }
        tableView.reloadData()
        navigationController?.popToViewController(self, animated: false)
        controller.dismiss(animated: true, completion: nil)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)

        reloadData()

        Analytics.track(.settingsSiriShortcutAdded)
    }

    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
    }

    // MARK: INUIEditVoiceShortcutViewControllerDelegate

    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        getEnabledShortcuts()
        reloadData()
        navigationController?.popToViewController(self, animated: false)
        controller.dismiss(animated: true, completion: nil)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
    }

    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        let shortcutsToDelete = enabledShortcuts.filter { $0.identifier == deletedVoiceShortcutIdentifier }
        if shortcutsToDelete.count > 0 {
            deleteEnabledShortcut(voiceShortcut: shortcutsToDelete[0])
        }
        navigationController?.popToViewController(self, animated: false)
        controller.dismiss(animated: true, completion: nil)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)

        Analytics.track(.settingsSiriShortcutRemoved)
    }

    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
    }

    @IBAction func tryAgainTapped() {
        getEnabledShortcuts()
    }
}
