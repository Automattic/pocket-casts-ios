import PocketCastsDataModel
import PocketCastsServer
import UIKit

class GeneralSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let timeStepperCellId = "TimeStepperCell"
    private let switchCellId = "SwitchCell"
    private let disclosureCellId = "DisclosureCell"
    
    private enum TableRow { case skipForward, skipBack, remoteSkipChapters, keepScreenAwake, openPlayer, intelligentPlaybackResumption, defaultRowAction, extraMediaActions, defaultAddToUpNextSwipe, defaultGrouping, defaultArchive, playUpNextOnTap, legacyBluetooth, multiSelectGesture, openLinksInBrowser, publishChapterTitles }
    private let tableData: [[TableRow]] = [[.defaultRowAction, .defaultGrouping, .defaultArchive, .defaultAddToUpNextSwipe, .openLinksInBrowser], [.skipForward, .skipBack, .keepScreenAwake, .openPlayer, .intelligentPlaybackResumption], [.playUpNextOnTap], [.remoteSkipChapters], [.extraMediaActions], [.legacyBluetooth], [.multiSelectGesture], [.publishChapterTitles]]
    
    @IBOutlet var settingsTable: UITableView! {
        didSet {
            settingsTable.register(UINib(nibName: "TimeStepperCell", bundle: nil), forCellReuseIdentifier: timeStepperCellId)
            settingsTable.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: switchCellId)
            settingsTable.register(UINib(nibName: "DisclosureCell", bundle: nil), forCellReuseIdentifier: disclosureCellId)
            settingsTable.applyInsetForMiniPlayer()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.settingsGeneral
    }
    
    // MARK: - UITableView Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = tableData[indexPath.section][indexPath.row]
        switch row {
        case .skipForward:
            let cell = tableView.dequeueReusableCell(withIdentifier: timeStepperCellId, for: indexPath) as! TimeStepperCell
            cell.cellLabel.text = L10n.skipForward
            let jumpFwdAmount = ServerSettings.skipForwardTime()
            cell.cellSecondaryLabel.text = L10n.timeShorthand(jumpFwdAmount)
            cell.timeStepper.currentValue = TimeInterval(jumpFwdAmount)
            cell.timeStepper.tintColor = ThemeColor.primaryInteractive01()
            cell.timeStepper.bigIncrements = 5.seconds
            cell.timeStepper.smallIncrements = 5.seconds
            cell.timeStepper.minimumValue = 0
            cell.timeStepper.maximumValue = 40.minutes
            
            cell.onValueChanged = { value in
                let newValue = Int(value)
                ServerSettings.setSkipForwardTime(newValue)
                cell.cellSecondaryLabel.text = L10n.timeShorthand(newValue)
                
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.skipTimesChanged)
            }
            
            return cell
        case .skipBack:
            let cell = tableView.dequeueReusableCell(withIdentifier: timeStepperCellId, for: indexPath) as! TimeStepperCell
            cell.cellLabel.text = L10n.skipBack
            let skipBackAmount = ServerSettings.skipBackTime()
            cell.cellSecondaryLabel.text = L10n.timeShorthand(skipBackAmount)
            cell.timeStepper.currentValue = TimeInterval(skipBackAmount)
            cell.timeStepper.tintColor = ThemeColor.primaryInteractive01()
            cell.timeStepper.bigIncrements = 5.seconds
            cell.timeStepper.smallIncrements = 5.seconds
            cell.timeStepper.minimumValue = 0
            cell.timeStepper.maximumValue = 40.minutes
            
            cell.onValueChanged = { value in
                let newValue = Int(value)
                ServerSettings.setSkipBackTime(newValue)
                cell.cellSecondaryLabel.text = L10n.timeShorthand(newValue)
                
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.skipTimesChanged)
            }
            
            return cell
        case .remoteSkipChapters:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            
            cell.cellLabel.text = L10n.settingsGeneralRemoteSkipsChapters
            cell.cellSwitch.isOn = Settings.remoteSkipShouldSkipChapters()
            
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(remoteSkipChanged(_:)), for: UIControl.Event.valueChanged)
            
            return cell
        case .keepScreenAwake:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            
            cell.cellLabel.text = L10n.settingsGeneralKeepScreenAwake
            cell.cellSwitch.isOn = UserDefaults.standard.bool(forKey: Constants.UserDefaults.keepScreenOnWhilePlaying)
            
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(screenLockToggled(_:)), for: UIControl.Event.valueChanged)
            
            return cell
        case .openLinksInBrowser:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            
            cell.cellLabel.text = L10n.settingsGeneralOpenInBrowser
            cell.cellSwitch.isOn = UserDefaults.standard.bool(forKey: Constants.UserDefaults.openLinksInExternalBrowser)
            
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(openLinksInBrowserToggled(_:)), for: UIControl.Event.valueChanged)
            
            return cell
        case .openPlayer:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            
            cell.cellLabel.text = L10n.settingsGeneralAutoOpenPlayer
            cell.cellSwitch.isOn = UserDefaults.standard.bool(forKey: Constants.UserDefaults.openPlayerAutomatically)
            
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(openPlayerToggled(_:)), for: UIControl.Event.valueChanged)
            
            return cell
        case .intelligentPlaybackResumption:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            
            cell.cellLabel.text = L10n.settingsGeneralSmartPlayback
            cell.cellSwitch.isOn = UserDefaults.standard.bool(forKey: Constants.UserDefaults.intelligentPlaybackResumption)
            
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(intelligentPlaybackResumptionToggled(_:)), for: UIControl.Event.valueChanged)
            
            return cell
        case .defaultRowAction:
            let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.settingsGeneralRowAction
            cell.cellSecondaryLabel.text = Settings.primaryRowAction() == .stream ? L10n.play : L10n.download
            
            return cell
        case .defaultArchive:
            let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.settingsGeneralArchivedEpisodes
            cell.cellSecondaryLabel.text = Settings.showArchivedDefault() ? L10n.settingsGeneralShow : L10n.settingsGeneralHide
            
            return cell
        case .defaultAddToUpNextSwipe:
            let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.settingsGeneralUpNextSwipe
            cell.cellSecondaryLabel.text = Settings.primaryUpNextSwipeAction() == .playNext ? L10n.playNext : L10n.playLast
            
            return cell
        case .defaultGrouping:
            let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.settingsGeneralEpisodeGroups
            
            // this label is quite wide at smaller than 370pt it won't fit, so don't show the value until they tap it
            if tableView.bounds.width > 370 {
                let grouping = Settings.defaultPodcastGrouping()
                cell.cellSecondaryLabel.text = grouping.description
            }
            else {
                cell.cellSecondaryLabel.text = nil
            }
            
            return cell
        case .playUpNextOnTap:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = L10n.settingsGeneralUpNextTap
            cell.cellSwitch.isOn = Settings.playUpNextOnTap()
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(playUpNextOnTapToggled(_:)), for: UIControl.Event.valueChanged)
            
            return cell
        case .extraMediaActions:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            
            cell.cellLabel.text = L10n.settingsGeneralPlayBackActions
            cell.cellSwitch.isOn = Settings.extraMediaSessionActionsEnabled()
            
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(extraMediaSessionActionsToggled(_:)), for: UIControl.Event.valueChanged)
            
            return cell
        case .legacyBluetooth:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            
            cell.cellLabel.text = L10n.settingsGeneralLegacyBluetooth
            cell.cellSwitch.isOn = Settings.legacyBluetoothModeEnabled()
            
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(legacyBluetoothToggled(_:)), for: UIControl.Event.valueChanged)
            
            return cell
        case .multiSelectGesture:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell
            
            cell.cellLabel.text = L10n.settingsGeneralMultiSelectGesture
            cell.cellSwitch.isOn = Settings.multiSelectGestureEnabled()
            
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(multiSelectGestureToggled(_:)), for: UIControl.Event.valueChanged)
            
            return cell
        case .publishChapterTitles:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId, for: indexPath) as! SwitchCell

            cell.cellLabel.text = L10n.settingsGeneralPublishChapterTitles
            cell.cellSwitch.isOn = Settings.publishChapterTitlesEnabled()

            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(publishChapterTitlesToggled(_:)), for: UIControl.Event.valueChanged)

            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = tableData[indexPath.section][indexPath.row]
        if row == .defaultRowAction {
            let currentAction = Settings.primaryRowAction()
            
            let options = OptionsPicker(title: L10n.settingsGeneralRowAction)
            let playAction = OptionAction(label: L10n.play, selected: currentAction == .stream) {
                Settings.setPrimaryRowAction(.stream)
                tableView.reloadData()
            }
            options.addAction(action: playAction)
            
            let downloadAction = OptionAction(label: L10n.download, selected: currentAction == .download) {
                Settings.setPrimaryRowAction(.download)
                tableView.reloadData()
            }
            options.addAction(action: downloadAction)
            options.show(statusBarStyle: preferredStatusBarStyle)
        }
        else if row == .defaultGrouping {
            let currentGrouping = Settings.defaultPodcastGrouping()
            
            let options = OptionsPicker(title: L10n.settingsGeneralEpisodeGroups)
            let noneAction = OptionAction(label: L10n.none, selected: currentGrouping == .none) { [weak self] in
                Settings.setDefaultPodcastGrouping(.none)
                
                tableView.reloadData()
                self?.promptToApplyGroupingToAll(grouping: Settings.defaultPodcastGrouping())
            }
            options.addAction(action: noneAction)
            
            let downloadedAction = OptionAction(label: L10n.statusDownloaded, selected: currentGrouping == .downloaded) { [weak self] in
                Settings.setDefaultPodcastGrouping(.downloaded)
                
                tableView.reloadData()
                self?.promptToApplyGroupingToAll(grouping: Settings.defaultPodcastGrouping())
            }
            options.addAction(action: downloadedAction)
            
            let unplayedAction = OptionAction(label: L10n.statusUnplayed, selected: currentGrouping == .unplayed) { [weak self] in
                Settings.setDefaultPodcastGrouping(.unplayed)
                
                tableView.reloadData()
                self?.promptToApplyGroupingToAll(grouping: Settings.defaultPodcastGrouping())
            }
            options.addAction(action: unplayedAction)
            
            let seasonAction = OptionAction(label: L10n.season, selected: currentGrouping == .season) { [weak self] in
                Settings.setDefaultPodcastGrouping(.season)
                
                tableView.reloadData()
                self?.promptToApplyGroupingToAll(grouping: Settings.defaultPodcastGrouping())
            }
            options.addAction(action: seasonAction)
            
            let starredAction = OptionAction(label: L10n.statusStarred, selected: currentGrouping == .starred) { [weak self] in
                Settings.setDefaultPodcastGrouping(.starred)
                
                tableView.reloadData()
                self?.promptToApplyGroupingToAll(grouping: Settings.defaultPodcastGrouping())
            }
            options.addAction(action: starredAction)
            
            options.show(statusBarStyle: preferredStatusBarStyle)
        }
        else if row == .defaultArchive {
            let currentlyShowingArchived = Settings.showArchivedDefault()
            
            let options = OptionsPicker(title: L10n.settingsGeneralArchivedEpisodes)
            let hideAction = OptionAction(label: L10n.settingsGeneralHide, selected: !currentlyShowingArchived) { [weak self] in
                Settings.setShowArchivedDefault(false)
                
                tableView.reloadData()
                self?.promptToApplyShowArchiveToAll(false)
            }
            options.addAction(action: hideAction)
            
            let showAction = OptionAction(label: L10n.settingsGeneralShow, selected: currentlyShowingArchived) { [weak self] in
                Settings.setShowArchivedDefault(true)
                
                tableView.reloadData()
                self?.promptToApplyShowArchiveToAll(true)
            }
            options.addAction(action: showAction)
            
            options.show(statusBarStyle: preferredStatusBarStyle)
        }
        else if row == .defaultAddToUpNextSwipe {
            let currentAction = Settings.primaryUpNextSwipeAction()
            
            let options = OptionsPicker(title: L10n.settingsGeneralUpNextSwipe)
            let playNextAction = OptionAction(label: L10n.playNext, selected: currentAction == .playNext) {
                Settings.setPrimaryUpNextSwipeAction(.playNext)
                tableView.reloadData()
            }
            options.addAction(action: playNextAction)
            
            let playLastAction = OptionAction(label: L10n.playLast, selected: currentAction == .playLast) {
                Settings.setPrimaryUpNextSwipeAction(.playLast)
                tableView.reloadData()
            }
            options.addAction(action: playLastAction)
            options.show(statusBarStyle: preferredStatusBarStyle)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerFrame = CGRect(x: 0, y: 0, width: 0, height: Constants.Values.tableSectionHeaderHeight)
        if section == 0 {
            return SettingsTableHeader(frame: headerFrame, title: L10n.settingsGeneralDefaultsHeader)
        }
        else if section == 1 {
            return SettingsTableHeader(frame: headerFrame, title: L10n.settingsGeneralPlayerHeader)
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Constants.Values.tableSectionHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return L10n.settingsGeneralSmartPlaybackSubtitle
        }
        else if section == 2 {
            return Settings.playUpNextOnTap() ? L10n.settingsGeneralUpNextTapOnSubtitle : L10n.settingsGeneralUpNextTapOffSubtitle
        }
        else if section == 3 {
            return L10n.settingsGeneralRemoteSkipsChaptersSubtitle
        }
        else if section == 4 {
            return L10n.settingsGeneralPlayBackActionsSubtitle
        }
        else if section == 5 {
            return L10n.settingsGeneralLegacyBluetoothSubtitle
        }
        else if section == 6 {
            return L10n.settingsGeneralMultiSelectGestureSubtitle
        }
        else if section == 7 {
            return L10n.settingsGeneralPublishChapterTitlesSubtitle
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }
    
    private func promptToApplyGroupingToAll(grouping: PodcastGrouping) {
        let groupingPrompt = OptionsPicker(title: nil)
        
        let applyToAllAction = OptionAction(label: L10n.settingsGeneralApplyAllConf, icon: nil) {
            DataManager.sharedManager.updateAllPodcastGrouping(to: grouping)
        }
        let noAction = OptionAction(label: L10n.settingsGeneralNoThanks, icon: nil) {
            // no need to do anything
        }
        noAction.outline = true
        
        let groupingMessage = grouping == .none ? L10n.settingsGeneralRemoveGroupsApplyAll : L10n.settingsGeneralSelectedGroupApplyAll(grouping.description.localizedLowercase)
        groupingPrompt.addDescriptiveActions(title: L10n.settingsGeneralApplyAllTitle, message: groupingMessage, icon: "option-podcasts", actions: [applyToAllAction, noAction])
        
        groupingPrompt.show(statusBarStyle: preferredStatusBarStyle)
    }
    
    private func promptToApplyShowArchiveToAll(_ showArchived: Bool) {
        let groupingPrompt = OptionsPicker(title: nil)
        
        let applyToAllAction = OptionAction(label: L10n.settingsGeneralApplyAllConf, icon: nil) {
            DataManager.sharedManager.updateAllShowArchived(to: showArchived)
        }
        let noAction = OptionAction(label: L10n.settingsGeneralNoThanks, icon: nil) {
            // no need to do anything
        }
        noAction.outline = true
        
        let groupingMessage = L10n.settingsGeneralArchivedEpisodesPromptFormat((showArchived ? L10n.settingsGeneralShow : L10n.settingsGeneralHide).localizedLowercase)
        groupingPrompt.addDescriptiveActions(title: L10n.settingsGeneralApplyAllTitle, message: groupingMessage, icon: "option-podcasts", actions: [applyToAllAction, noAction])
        
        groupingPrompt.show(statusBarStyle: preferredStatusBarStyle)
    }
    
    @objc private func screenLockToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: Constants.UserDefaults.keepScreenOnWhilePlaying)
        PlaybackManager.shared.updateIdleTimer()
    }
    
    @objc private func openLinksInBrowserToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: Constants.UserDefaults.openLinksInExternalBrowser)
    }
    
    @objc private func legacyBluetoothToggled(_ sender: UISwitch) {
        Settings.setLegacyBluetoothModeEnabled(sender.isOn)
    }
    
    @objc private func multiSelectGestureToggled(_ sender: UISwitch) {
        Settings.setMultiSelectGestureEnabled(sender.isOn)
    }
    
    @objc private func extraMediaSessionActionsToggled(_ sender: UISwitch) {
        Settings.setExtraMediaSessionActionsEnabled(sender.isOn)
    }
    
    @objc private func remoteSkipChanged(_ sender: UISwitch) {
        Settings.setRemoteSkipShouldSkipChapters(sender.isOn)
    }
    
    @objc private func openPlayerToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: Constants.UserDefaults.openPlayerAutomatically)
    }
    
    @objc private func intelligentPlaybackResumptionToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: Constants.UserDefaults.intelligentPlaybackResumption)
    }
    
    @objc private func playUpNextOnTapToggled(_ sender: UISwitch) {
        Settings.setPlayUpNextOnTap(sender.isOn)
        settingsTable.reloadData()
    }
    
    @objc private func publishChapterTitlesToggled(_ sender: UISwitch) {
        Settings.setPublishChapterTitlesEnabled(sender.isOn)

        PlaybackManager.shared.playerDidChangeNowPlayingInfo()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }
}
