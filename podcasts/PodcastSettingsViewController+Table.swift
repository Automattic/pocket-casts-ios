import IntentsUI
import PocketCastsDataModel
import PocketCastsServer
import UIKit

extension PodcastSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    private static let disclosureCellId = "DisclosureCell"
    private static let switchCellId = "SwitchCell"
    private static let timeStepperCellId = "TimeStepperCell"
    private static let createSiriShortcutCellId = "CreateSiriShortcutCell"
    private static let siriEnabledCellId = "siriEnabledCellId"
    private static let destructiveButtonCellId = "destructiveButtonCell"
    
    func registerCells() {
        settingsTable.register(UINib(nibName: "DisclosureCell", bundle: nil), forCellReuseIdentifier: PodcastSettingsViewController.disclosureCellId)
        settingsTable.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: PodcastSettingsViewController.switchCellId)
        settingsTable.register(UINib(nibName: "TimeStepperCell", bundle: nil), forCellReuseIdentifier: PodcastSettingsViewController.timeStepperCellId)
        settingsTable.register(UINib(nibName: "SiriShortcutEnabledCell", bundle: nil), forCellReuseIdentifier: PodcastSettingsViewController.siriEnabledCellId)
        settingsTable.register(UINib(nibName: "CreateSiriShortcutCell", bundle: nil), forCellReuseIdentifier: PodcastSettingsViewController.createSiriShortcutCellId)
        settingsTable.register(UINib(nibName: "DestructiveButtonCell", bundle: nil), forCellReuseIdentifier: PodcastSettingsViewController.destructiveButtonCellId)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        tableData().count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData()[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = tableData()[indexPath.section][indexPath.row]
        
        switch row {
        case .feedError:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.Localizable.settingsFeedError
            cell.setImage(imageName: "option-alert", tintColor: podcast.iconTintColor())
            
            cell.cellSecondaryLabel.text = nil
            
            return cell
        case .autoDownload:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = L10n.Localizable.settingsAutoDownload
            cell.cellSwitch.onTintColor = podcast.switchTintColor()
            cell.setImage(imageName: "download")
            cell.cellSwitch.isOn = podcast.autoDownloadOn() && Settings.autoDownloadEnabled()
            
            cell.cellSwitch.removeTarget(self, action: #selector(autoDownloadChanged(_:)), for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(autoDownloadChanged(_:)), for: UIControl.Event.valueChanged)
            
            return cell
        case .notifications:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = L10n.Localizable.settingsNotifications
            cell.cellSwitch.onTintColor = podcast.switchTintColor()
            cell.setImage(imageName: "settings-notifications")
            cell.cellSwitch.isOn = podcast.pushEnabled && NotificationsHelper.shared.pushEnabled()
            
            cell.cellSwitch.removeTarget(self, action: #selector(notificationChanged(_:)), for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(notificationChanged(_:)), for: UIControl.Event.valueChanged)
            
            return cell
        case .upNext:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = L10n.Localizable.addToUpNext
            cell.cellSwitch.onTintColor = podcast.switchTintColor()
            cell.setImage(imageName: "upnext")
            cell.cellSwitch.isOn = podcast.autoAddToUpNextOn()
            
            cell.cellSwitch.removeTarget(self, action: #selector(addToUpNextChanged(_:)), for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(addToUpNextChanged(_:)), for: UIControl.Event.valueChanged)
            
            return cell
        case .upNextPosition:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.Localizable.settingsQueuePosition
            cell.setImage(imageName: nil)
            
            let upNextOrder = Int(podcast.autoAddToUpNext)
            cell.cellSecondaryLabel.text = (upNextOrder == AutoAddToUpNextSetting.addLast.rawValue) ? L10n.Localizable.bottom : L10n.Localizable.top
            
            return cell
        case .globalUpNext:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.Localizable.settingsGlobalSettings
            cell.setImage(imageName: nil)
            
            cell.cellSecondaryLabel.text = L10n.Localizable.settingsEpisodeLimitFormat(ServerSettings.autoAddToUpNextLimit().localized())
            
            return cell
        case .playbackEffects:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = PlayerAction.effects.title()
            let imageName = podcast.overrideGlobalEffects ? "podcast-effects-on" : "podcast-effects-off"
            cell.setImage(imageName: imageName, tintColor: podcast.iconTintColor())
            cell.cellSecondaryLabel.text = nil
            
            return cell
        case .skipFirst:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.timeStepperCellId, for: indexPath) as! TimeStepperCell
            cell.cellLabel.text = L10n.Localizable.settingsSkipFirst
            cell.cellSecondaryLabel.text = L10n.timeShorthand(Int(podcast.startFrom))
            cell.timeStepper.tintColor = podcast.iconTintColor()
            cell.timeStepper.minimumValue = 0
            cell.timeStepper.maximumValue = 40.minutes
            cell.timeStepper.bigIncrements = 5.seconds
            cell.timeStepper.smallIncrements = 5.seconds
            cell.timeStepper.currentValue = TimeInterval(podcast.startFrom)
            cell.configureWithImage(imageName: "settings-skipintros", tintColor: podcast.iconTintColor())
            
            cell.onValueChanged = { [weak self] value in
                guard let podcast = self?.podcast else { return }
                
                podcast.startFrom = Int32(value)
                podcast.syncStatus = SyncStatus.notSynced.rawValue
                DataManager.sharedManager.save(podcast: podcast)
                cell.cellSecondaryLabel.text = L10n.timeShorthand(Int(podcast.startFrom))
            }
            
            return cell
        case .skipLast:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.timeStepperCellId, for: indexPath) as! TimeStepperCell
            cell.cellLabel.text = L10n.Localizable.settingsSkipLast
            cell.cellSecondaryLabel.text = L10n.timeShorthand(Int(podcast.skipLast))
            cell.timeStepper.tintColor = podcast.iconTintColor()
            cell.timeStepper.minimumValue = 0
            cell.timeStepper.maximumValue = 40.minutes
            cell.timeStepper.bigIncrements = 5.seconds
            cell.timeStepper.smallIncrements = 5.seconds
            cell.timeStepper.currentValue = TimeInterval(podcast.skipLast)
            cell.configureWithImage(imageName: "settings-skipoutros", tintColor: podcast.iconTintColor())
            
            cell.onValueChanged = { [weak self] value in
                guard let podcast = self?.podcast else { return }
                
                podcast.skipLast = Int32(value)
                podcast.syncStatus = SyncStatus.notSynced.rawValue
                DataManager.sharedManager.save(podcast: podcast)
                cell.cellSecondaryLabel.text = L10n.timeShorthand(Int(podcast.skipLast))
            }
            
            return cell
        case .autoArchive:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.Localizable.settingsAutoArchive
            cell.setImage(imageName: "list_archive", tintColor: podcast.iconTintColor())
            cell.cellSecondaryLabel.text = nil
            
            return cell
        case .inFilters:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellSecondaryLabel.text = nil
            cell.setImage(imageName: "settings_filter", tintColor: podcast.iconTintColor())
            
            let filterCount = filterUuidsPodcastAppearsIn().count
            if filterCount == 0 {
                cell.cellLabel.text = L10n.Localizable.settingsNotInFilters
            }
            else {
                cell.cellLabel.text = filterCount == 1 ? L10n.Localizable.settingsInFiltersSingular : L10n.Localizable.settingsInFiltersPluralFormat(filterCount.localized())
            }
            
            return cell
        case .siriShortcut:
            if existingShortcut != nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.siriEnabledCellId) as! SiriShortcutEnabledCell
                cell.titleLabel.text = L10n.Localizable.settingsSiriShortcut
                let existingShortcutPhrase = existingSiriVoiceShortcut().invocationPhrase
                cell.phraseLabel.text = "\"\(existingShortcutPhrase)\""
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.createSiriShortcutCellId) as! CreateSiriShortcutCell
                cell.buttonTitle.text = L10n.Localizable.settingsCreateSiriShortcut
                
                return cell
            }
        case .unsubscribe:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.destructiveButtonCellId, for: indexPath) as! DestructiveButtonCell
            cell.buttonTitle.text = L10n.Localizable.unsubscribe
            cell.buttonTitle.textColor = ThemeColor.support05()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = tableData()[indexPath.section][indexPath.row]
        if row == .upNextPosition {
            showAutoAddPositionSettings()
        }
        else if row == .feedError {
            let alert = UIAlertController(title: L10n.Localizable.settingsFeedIssue, message: L10n.Localizable.settingsFeedIssueMsg, preferredStyle: UIAlertController.Style.alert)
                
            let okAction = UIAlertAction(title: L10n.Localizable.cancel, style: .cancel, handler: nil)
            alert.addAction(okAction)
            
            let refreshAction = UIAlertAction(title: L10n.Localizable.settingsFeedFixRefresh, style: .default) { _ in
                MainServerHandler.shared.refreshPodcastFeed(podcast: self.podcast) { success in
                    if success {
                        SJUIUtils.showAlert(title: L10n.Localizable.settingsFeedFixRefreshSuccessTitle, message: L10n.Localizable.settingsFeedFixRefreshSuccessMsg, from: self)
                    }
                    else {
                        SJUIUtils.showAlert(title: L10n.Localizable.settingsFeedFixRefreshFailedTitle, message: L10n.Localizable.settingsFeedFixRefreshFailedMsg, from: self)
                    }
                }
            }
            alert.addAction(refreshAction)
            
            present(alert, animated: true, completion: nil)
        }
        else if row == .globalUpNext {
            let globalSettings = AutoAddToUpNextViewController()
            navigationController?.pushViewController(globalSettings, animated: true)
        }
        else if row == .playbackEffects {
            let effectsController = PodcastEffectsViewController(podcast: podcast)
            navigationController?.pushViewController(effectsController, animated: true)
        }
        else if row == .autoArchive {
            let archiveController = PodcastArchiveViewController(podcast: podcast)
            navigationController?.pushViewController(archiveController, animated: true)
        }
        else if row == .inFilters {
            let filterSelectionViewController = FilterSelectionViewController()
            filterSelectionViewController.allFilters = filtersPodcastCanAppearIn()
            filterSelectionViewController.selectedFilters = filterUuidsPodcastAppearsIn()
            filterSelectionViewController.filterSelected = { [weak self] filter in
                guard let self = self else { return }
                
                filter.addPodcast(podcastUuid: self.podcast.uuid)
                DataManager.sharedManager.save(filter: filter)
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged)
            }
            filterSelectionViewController.filterUnselected = { [weak self] filter in
                guard let self = self else { return }
                
                filter.removePodcast(podcastUuid: self.podcast.uuid)
                DataManager.sharedManager.save(filter: filter)
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged)
            }
            navigationController?.pushViewController(filterSelectionViewController, animated: true)
        }
        else if row == .siriShortcut {
            if let voiceShortcut = existingSiriVoiceShortcut() {
                let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: voiceShortcut)
                viewController.modalPresentationStyle = .formSheet
                viewController.delegate = self
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
                present(viewController, animated: true, completion: nil)
            }
            else {
                showINAddVoiceShortcutVC()
            }
        }
        else if row == .unsubscribe {
            unsubscribe()
        }
    }
    
    // MARK: - Table Config
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // remove the standard padding from the top of a grouped UITableView
        section == 0 ? CGFloat.leastNonzeroMagnitude : 19
    }
    
    // MARK: - Table Footer Text
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let firstRow = tableData()[section][0]
        
        if firstRow == .upNext {
            let upNextLimit = ServerSettings.autoAddToUpNextLimit()
            let onLimitReached = ServerSettings.onAutoAddLimitReached()
            if onLimitReached == .addToTopOnly {
                return L10n.Localizable.settingsUpNextLimitAddToTop(upNextLimit.localized())
            }
            else {
                return L10n.Localizable.settingsUpNextLimit(upNextLimit.localized())
            }
        }
        else if firstRow == .feedError {
            return L10n.Localizable.settingsFeedErrorMsg
        }
        else if firstRow == .autoArchive {
            return nil
        }
        else if firstRow == .playbackEffects {
            return L10n.Localizable.settingsSkipMsg
        }
        else if firstRow == .siriShortcut, let name = podcast.title {
            let format = existingShortcut != nil ? L10n.Localizable.settingsSiriShortcutMsg : L10n.Localizable.settingsCreateSiriShortcutMsg
            return format(name)
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }
    
    // MARK: - Auto Add To Up Next
    
    private func showAutoAddPositionSettings() {
        let positionPicker = OptionsPicker(title: L10n.Localizable.autoAdd.localizedUppercase)
        
        let topAction = OptionAction(label: L10n.Localizable.top, icon: nil) {
            self.setUpNext(.addFirst)
        }
        positionPicker.addAction(action: topAction)
        
        let bottomAction = OptionAction(label: L10n.Localizable.bottom, icon: nil) {
            self.setUpNext(.addLast)
        }
        positionPicker.addAction(action: bottomAction)
        
        positionPicker.show(statusBarStyle: preferredStatusBarStyle)
    }
    
    private func setUpNext(_ setting: AutoAddToUpNextSetting) {
        podcast.autoAddToUpNext = setting.rawValue
        DataManager.sharedManager.save(podcast: podcast)
        settingsTable.reloadData()
    }
    
    // MARK: - Settings changes
    
    @objc private func autoDownloadChanged(_ sender: UISwitch) {
        if sender.isOn {
            podcast.autoDownloadSetting = AutoDownloadSetting.latest.rawValue
            Settings.setAutoDownloadEnabled(true)
        }
        else {
            podcast.autoDownloadSetting = AutoDownloadSetting.off.rawValue
        }
        DataManager.sharedManager.save(podcast: podcast)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast.uuid)
    }
    
    @objc private func addToUpNextChanged(_ sender: UISwitch) {
        if sender.isOn {
            podcast.autoAddToUpNext = AutoAddToUpNextSetting.addLast.rawValue
        }
        else {
            podcast.autoAddToUpNext = AutoAddToUpNextSetting.off.rawValue
        }
        
        settingsTable.reloadData()
        DataManager.sharedManager.save(podcast: podcast)
    }
    
    @objc private func notificationChanged(_ sender: UISwitch) {
        PodcastManager.shared.setNotificationsEnabled(podcast: podcast, enabled: sender.isOn)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast.uuid)
    }
    
    private func tableData() -> [[TableRow]] {
        var data: [[TableRow]] = [[.autoDownload, .notifications], [.upNext], [.playbackEffects, .skipFirst, .skipLast], [.autoArchive]]
        
        if podcast.refreshAvailable {
            data.insert([.feedError], at: 0)
        }
        
        if podcast.autoAddToUpNextOn() {
            data[1].append(.upNextPosition)
            data[1].append(.globalUpNext)
        }
        
        if filtersPodcastCanAppearIn().count > 0 {
            data.append([.inFilters])
        }
        data.append([.siriShortcut])
        data.append([.unsubscribe])
        
        return data
    }
    
    private func filterUuidsPodcastAppearsIn() -> [String] {
        DataManager.sharedManager.allFilters(includeDeleted: false).compactMap { filter -> String? in
            filter.podcastUuids.contains(podcast.uuid) ? filter.uuid : nil
        }
    }
    
    private func filtersPodcastCanAppearIn() -> [EpisodeFilter] {
        DataManager.sharedManager.allFilters(includeDeleted: false).filter { filter -> Bool in
            filter.filterAllPodcasts == false
        }
    }
    
    // MARK: - Siri shortcuts helper function
    
    private func showINAddVoiceShortcutVC() {
        let viewController = INUIAddVoiceShortcutViewController(shortcut: SiriShortcutsManager.shared.playPodcastShortcut(podcast: podcast))
        viewController.modalPresentationStyle = .formSheet
        viewController.delegate = self
        present(viewController, animated: true, completion: nil)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
    }
}
