import IntentsUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
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
            cell.cellLabel.text = L10n.settingsFeedError
            cell.setImage(imageName: "option-alert", tintColor: podcast.iconTintColor())

            cell.cellSecondaryLabel.text = nil

            return cell
        case .autoDownload:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = L10n.settingsAutoDownload
            cell.cellSwitch.onTintColor = podcast.switchTintColor()
            cell.setImage(imageName: "download")
            cell.cellSwitch.isOn = podcast.autoDownloadOn() && Settings.autoDownloadEnabled()

            cell.cellSwitch.removeTarget(self, action: #selector(autoDownloadChanged(_:)), for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(autoDownloadChanged(_:)), for: UIControl.Event.valueChanged)

            return cell
        case .notifications:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = L10n.settingsNotifications
            cell.cellSwitch.onTintColor = podcast.switchTintColor()
            cell.setImage(imageName: "settings_notifications")
            cell.cellSwitch.isOn = podcast.isPushEnabled && NotificationsHelper.shared.pushEnabled()

            cell.cellSwitch.removeTarget(self, action: #selector(notificationChanged(_:)), for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(notificationChanged(_:)), for: UIControl.Event.valueChanged)

            return cell
        case .upNext:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = L10n.addToUpNext
            cell.cellSwitch.onTintColor = podcast.switchTintColor()
            cell.setImage(imageName: "upnext")
            cell.cellSwitch.isOn = podcast.autoAddToUpNextOn()

            cell.cellSwitch.removeTarget(self, action: #selector(addToUpNextChanged(_:)), for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(addToUpNextChanged(_:)), for: UIControl.Event.valueChanged)

            return cell
        case .upNextPosition:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.settingsQueuePosition
            cell.setImage(imageName: nil)

            let upNextOrder = podcast.autoAddToUpNextSetting()?.rawValue
            cell.cellSecondaryLabel.text = (upNextOrder == AutoAddToUpNextSetting.addLast.rawValue) ? L10n.bottom : L10n.top

            return cell
        case .globalUpNext:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.settingsGlobalSettings
            cell.setImage(imageName: nil)

            cell.cellSecondaryLabel.text = L10n.settingsEpisodeLimitFormat(ServerSettings.autoAddToUpNextLimit().localized())

            return cell
        case .playbackEffects:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = PlayerAction.effects.title()
            let imageName = podcast.isEffectsOverridden ? "podcast-effects-on" : "podcast-effects-off"
            cell.setImage(imageName: imageName, tintColor: podcast.iconTintColor())
            cell.cellSecondaryLabel.text = nil

            return cell
        case .skipFirst:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.timeStepperCellId, for: indexPath) as! TimeStepperCell
            cell.cellLabel.text = L10n.settingsSkipFirst
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

                podcast.autoStartFrom = Int32(value)
                podcast.syncStatus = SyncStatus.notSynced.rawValue
                DataManager.sharedManager.save(podcast: podcast)
                cell.cellSecondaryLabel.text = L10n.timeShorthand(Int(podcast.autoStartFrom))

                self?.debounce.call {
                    Analytics.track(.podcastSettingsSkipFirstChanged, properties: ["value": value])
                }
            }

            return cell
        case .skipLast:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.timeStepperCellId, for: indexPath) as! TimeStepperCell
            cell.cellLabel.text = L10n.settingsSkipLast
            cell.cellSecondaryLabel.text = L10n.timeShorthand(Int(podcast.skipLast))
            cell.timeStepper.tintColor = podcast.iconTintColor()
            cell.timeStepper.minimumValue = 0
            cell.timeStepper.maximumValue = 40.minutes
            cell.timeStepper.bigIncrements = 5.seconds
            cell.timeStepper.smallIncrements = 5.seconds
            cell.timeStepper.currentValue = TimeInterval(podcast.autoSkipLast)
            cell.configureWithImage(imageName: "settings-skipoutros", tintColor: podcast.iconTintColor())

            cell.onValueChanged = { [weak self] value in
                guard let podcast = self?.podcast else { return }

                podcast.autoSkipLast = Int32(value)
                podcast.syncStatus = SyncStatus.notSynced.rawValue
                DataManager.sharedManager.save(podcast: podcast)
                cell.cellSecondaryLabel.text = L10n.timeShorthand(Int(podcast.autoSkipLast))

                self?.debounce.call {
                    Analytics.track(.podcastSettingsSkipLastChanged, properties: ["value": value])
                }
            }

            return cell
        case .autoArchive:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.settingsAutoArchive
            cell.setImage(imageName: "list_archive", tintColor: podcast.iconTintColor())
            cell.cellSecondaryLabel.text = nil

            return cell
        case .inFilters:
            let playlistRebrandingEnabled = FeatureFlag.playlistsRebranding.enabled
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellSecondaryLabel.text = nil
            cell.setImage(
                imageName: playlistRebrandingEnabled ? "playlists_tab" : "settings_filter",
                tintColor: podcast.iconTintColor()
            )

            let playlistsCount = playlistUuidsPodcastAppearsIn().count
            if playlistsCount == 0 {
                cell.cellLabel.text = playlistRebrandingEnabled ? L10n.settingsNotInSmartPlaylists : L10n.settingsNotInFilters
            } else {
                cell.cellLabel.text = if playlistsCount == 1 {
                    playlistRebrandingEnabled ? L10n.settingsInSmartPlaylistSingular : L10n.settingsInFiltersSingular
                } else {
                    playlistRebrandingEnabled ? L10n.settingsInSmartPlaylistsPluralFormat(playlistsCount.localized()) : L10n.settingsInFiltersPluralFormat(playlistsCount.localized())
                }
            }

            return cell
        case .siriShortcut:
            if existingShortcut != nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.siriEnabledCellId) as! SiriShortcutEnabledCell
                cell.titleLabel.text = L10n.settingsSiriShortcut
                let existingShortcutPhrase = existingSiriVoiceShortcut().invocationPhrase
                cell.phraseLabel.text = "\"\(existingShortcutPhrase)\""
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.createSiriShortcutCellId) as! CreateSiriShortcutCell
                cell.buttonTitle.text = L10n.settingsCreateSiriShortcut

                return cell
            }
        case .unsubscribe:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastSettingsViewController.destructiveButtonCellId, for: indexPath) as! DestructiveButtonCell
            cell.buttonTitle.text = FeatureFlag.useFollowNaming.enabled ? L10n.unfollow : L10n.unsubscribe
            cell.buttonTitle.textColor = ThemeColor.support05()
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = tableData()[indexPath.section][indexPath.row]
        if row == .upNextPosition {
            showAutoAddPositionSettings()
        } else if row == .feedError {
            Analytics.track(.podcastSettingsFeedErrorTapped)

            let alert = UIAlertController(title: L10n.settingsFeedIssue, message: L10n.settingsFeedIssueMsg, preferredStyle: UIAlertController.Style.alert)

            let okAction = UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil)
            alert.addAction(okAction)

            let refreshAction = UIAlertAction(title: L10n.settingsFeedFixRefresh, style: .default) { _ in
                Analytics.track(.podcastSettingsFeedErrorUpdateTapped)

                MainServerHandler.shared.refreshPodcastFeed(podcast: self.podcast) { success in
                    if success {
                        Analytics.track(.podcastSettingsFeedErrorFixSucceeded)
                        SJUIUtils.showAlert(title: L10n.settingsFeedFixRefreshSuccessTitle, message: L10n.settingsFeedFixRefreshSuccessMsg, from: self)
                    } else {
                        Analytics.track(.podcastSettingsFeedErrorFixFailed)
                        SJUIUtils.showAlert(title: L10n.settingsFeedFixRefreshFailedTitle, message: L10n.settingsFeedFixRefreshFailedMsg, from: self)
                    }
                }
            }
            alert.addAction(refreshAction)

            present(alert, animated: true, completion: nil)
        } else if row == .globalUpNext {
            let globalSettings = AutoAddToUpNextViewController()
            navigationController?.pushViewController(globalSettings, animated: true)
        } else if row == .playbackEffects {
            let effectsController = PodcastEffectsViewController(podcast: podcast)
            navigationController?.pushViewController(effectsController, animated: true)
        } else if row == .autoArchive {
            let archiveController = PodcastArchiveViewController(podcast: podcast)
            navigationController?.pushViewController(archiveController, animated: true)
        } else if row == .inFilters {
            let playlistSelectionViewController = PlaylistSelectionViewController()
            playlistSelectionViewController.navigationTitle = FeatureFlag.playlistsRebranding.enabled ? L10n.settingsSelectSmartPlaylistsPlural : L10n.settingsSelectFiltersPlural
            playlistSelectionViewController.allPlaylists = playlistsPodcastCanAppearIn()
            playlistSelectionViewController.selectedPlaylists = playlistUuidsPodcastAppearsIn()
            playlistSelectionViewController.playlistSelected = { [weak self] playlist in
                guard let self = self else { return }

                playlist.addPodcast(podcastUuid: self.podcast.uuid)
                DataManager.sharedManager.save(playlist: playlist)
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)

                Analytics.track(.filterUpdated, properties: ["group": "podcasts", "source": "podcast_settings"])
            }
            playlistSelectionViewController.playlistUnselected = { [weak self] playlist in
                guard let self = self else { return }

                playlist.removePodcast(podcastUuid: self.podcast.uuid)
                DataManager.sharedManager.save(playlist: playlist)
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)

                Analytics.track(.filterUpdated, properties: ["group": "podcasts", "source": "podcast_settings"])
            }
            navigationController?.pushViewController(playlistSelectionViewController, animated: true)
        } else if row == .siriShortcut {
            if let voiceShortcut = existingSiriVoiceShortcut() {
                let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: voiceShortcut)
                viewController.modalPresentationStyle = .formSheet
                viewController.delegate = self
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
                present(viewController, animated: true, completion: nil)
            } else {
                showINAddVoiceShortcutVC()
            }
        } else if row == .unsubscribe {
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
                return L10n.settingsUpNextLimitAddToTop(upNextLimit.localized())
            } else {
                return L10n.settingsUpNextLimit(upNextLimit.localized())
            }
        } else if firstRow == .feedError {
            return L10n.settingsFeedErrorMsg
        } else if firstRow == .autoArchive {
            return nil
        } else if firstRow == .playbackEffects {
            return L10n.settingsSkipMsg
        } else if firstRow == .siriShortcut, let name = podcast.title {
            let format = existingShortcut != nil ? L10n.settingsSiriShortcutMsg : L10n.settingsCreateSiriShortcutMsg
            return format(name)
        }

        return nil
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }

    // MARK: - Auto Add To Up Next

    private func showAutoAddPositionSettings() {
        let positionPicker = OptionsPicker(title: L10n.autoAdd.localizedUppercase)

        let topAction = OptionAction(label: L10n.top, icon: nil) {
            self.setUpNext(.addFirst)
        }
        positionPicker.addAction(action: topAction)

        let bottomAction = OptionAction(label: L10n.bottom, icon: nil) {
            self.setUpNext(.addLast)
        }
        positionPicker.addAction(action: bottomAction)

        positionPicker.show(statusBarStyle: preferredStatusBarStyle)
    }

    private func setUpNext(_ setting: AutoAddToUpNextSetting) {
        podcast.setAutoAddToUpNext(setting: setting)
        podcast.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(podcast: podcast)
        settingsTable.reloadData()

        Analytics.track(.podcastSettingsAutoAddUpNextPositionOptionChanged, properties: ["value": setting])
    }

    // MARK: - Settings changes

    @objc private func autoDownloadChanged(_ sender: UISwitch) {
        if sender.isOn {
            podcast.autoDownloadSetting = AutoDownloadSetting.latest.rawValue
            Settings.setAutoDownloadEnabled(true, userInitiated: true)
        } else {
            podcast.autoDownloadSetting = AutoDownloadSetting.off.rawValue
        }
        DataManager.sharedManager.save(podcast: podcast)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast.uuid)

        Analytics.track(.podcastSettingsAutoDownloadToggled, properties: ["enabled": sender.isOn])
    }

    @objc private func addToUpNextChanged(_ sender: UISwitch) {
        if sender.isOn {
            podcast.setAutoAddToUpNext(setting: .addLast)
        } else {
            podcast.setAutoAddToUpNext(setting: .off)
        }

        settingsTable.reloadData()
        DataManager.sharedManager.save(podcast: podcast)
        Analytics.track(.podcastSettingsAutoAddUpNextToggled, properties: ["enabled": sender.isOn])
    }

    @objc private func notificationChanged(_ sender: UISwitch) {
        Analytics.track(.podcastSettingsNotificationsToggled, properties: ["enabled": sender.isOn])
        NotificationsHelper.shared.registerForPushNotifications() { [weak self] granted in
            guard let self, granted || !sender.isOn else {
                Toast.show(L10n.notificationsPermissionsNeedsAction, actions: [.init(title: L10n.notificationsPermissionsOpenSettings, action: {
                    Analytics.track(.notificationsPermissionsOpenSystemSettings)
                    UIApplication.shared.openNotificationSettings()
                })])
                sender.isOn = false
                return
            }
            PodcastManager.shared.setNotificationsEnabled(podcast: self.podcast, enabled: sender.isOn)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast.uuid)
        }
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

        if playlistsPodcastCanAppearIn().count > 0 {
            data.append([.inFilters])
        }
        data.append([.siriShortcut])
        data.append([.unsubscribe])

        return data
    }

    private func playlistUuidsPodcastAppearsIn() -> [String] {
        DataManager.sharedManager.allSmartPlaylists(includeDeleted: false).compactMap { playlist -> String? in
            playlist.podcastUuids.contains(podcast.uuid) ? playlist.uuid : nil
        }
    }

    private func playlistsPodcastCanAppearIn() -> [EpisodeFilter] {
        DataManager.sharedManager.allSmartPlaylists(includeDeleted: false).filter { playlist -> Bool in
            playlist.filterAllPodcasts == false
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
