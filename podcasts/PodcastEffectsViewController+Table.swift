import PocketCastsDataModel

extension PodcastEffectsViewController: UITableViewDataSource, UITableViewDelegate {
    private static let disclosureCellId = "DisclosureCell"
    private static let switchCellId = "SwitchCell"
    private static let timeStepperCellId = "TimeStepperCell"

    private enum TableRow { case customForPodcast, playbackSpeed, trimSilence, trimSilenceAmount, volumeBoost }

    func registerCells() {
        effectsTable.register(UINib(nibName: "DisclosureCell", bundle: nil), forCellReuseIdentifier: PodcastEffectsViewController.disclosureCellId)
        effectsTable.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: PodcastEffectsViewController.switchCellId)
        effectsTable.register(UINib(nibName: "TimeStepperCell", bundle: nil), forCellReuseIdentifier: PodcastEffectsViewController.timeStepperCellId)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        podcast.overrideGlobalEffects ? 2 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData()[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableRow = tableData()[indexPath.section][indexPath.row]

        switch tableRow {
        case .customForPodcast:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastEffectsViewController.switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel?.text = L10n.settingsCustom
            cell.cellSwitch.onTintColor = podcast.switchTintColor()
            cell.cellSwitch.isOn = podcast.overrideGlobalEffects
            cell.setNoImage()

            cell.cellSwitch.removeTarget(self, action: #selector(overrideEffectsToggled(_:)), for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(overrideEffectsToggled(_:)), for: UIControl.Event.valueChanged)

            return cell
        case .playbackSpeed:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastEffectsViewController.timeStepperCellId, for: indexPath) as! TimeStepperCell
            cell.cellLabel?.text = L10n.settingsPlaySpeed
            cell.cellSecondaryLabel.text = L10n.playbackSpeed(podcast.playbackSpeed.localized())
            cell.configureWithImage(imageName: "player_speed", tintColor: podcast.iconTintColor())

            cell.timeStepper.tintColor = podcast.iconTintColor()
            cell.timeStepper.minimumValue = 0.5
            cell.timeStepper.maximumValue = 3
            cell.timeStepper.smallIncrements = 0.1
            cell.timeStepper.smallIncrementThreshold = TimeInterval.greatestFiniteMagnitude
            cell.timeStepper.currentValue = podcast.playbackSpeed

            cell.onValueChanged = { [weak self] value in
                self?.playbackSpeedChanged(value)
            }

            return cell
        case .trimSilence:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastEffectsViewController.switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel?.text = L10n.settingsTrimSilence
            cell.cellSwitch.onTintColor = podcast.switchTintColor()
            cell.setImage(imageName: "player_trim")
            cell.cellSwitch.isOn = podcast.trimSilenceAmount > 0

            cell.cellSwitch.removeTarget(self, action: #selector(trimSilenceToggled(_:)), for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(trimSilenceToggled(_:)), for: UIControl.Event.valueChanged)

            return cell
        case .trimSilenceAmount:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastEffectsViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel?.text = L10n.settingsTrimLevel
            cell.setImage(imageName: nil)

            let trimAmount = TrimSilenceAmount(rawValue: Int(podcast.trimSilenceAmount)) ?? .low
            cell.cellSecondaryLabel.text = trimAmount.description

            return cell
        case .volumeBoost:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastEffectsViewController.switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel?.text = L10n.settingsVolumeBoost
            cell.cellSwitch.onTintColor = podcast.switchTintColor()
            cell.setImage(imageName: "player_volumeboost")
            cell.cellSwitch.isOn = podcast.boostVolume

            cell.cellSwitch.removeTarget(self, action: #selector(boostVolumeToggled(_:)), for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(boostVolumeToggled(_:)), for: UIControl.Event.valueChanged)

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let tableRow = tableData()[indexPath.section][indexPath.row]

        if tableRow == .trimSilenceAmount {
            let options = OptionsPicker(title: L10n.settingsTrimLevel)
            addTrimLevelAction(level: .low, to: options)
            addTrimLevelAction(level: .medium, to: options)
            addTrimLevelAction(level: .high, to: options)

            options.show(statusBarStyle: preferredStatusBarStyle)
        }
    }

    private func addTrimLevelAction(level: TrimSilenceAmount, to: OptionsPicker) {
        let selectedAmount = TrimSilenceAmount(rawValue: Int(podcast.trimSilenceAmount)) ?? .low
        let action = OptionAction(label: level.description, selected: selectedAmount == level) { [weak self] in
            guard let self = self else { return }

            self.podcast.trimSilenceAmount = Int32(level.rawValue)
            DataManager.sharedManager.save(podcast: self.podcast)

            self.effectsTable.reloadData()
            AnalyticsPlaybackHelper.shared.currentSource = self.analyticsSource
            AnalyticsPlaybackHelper.shared.trimSilenceAmountChanged(amount: level)
        }
        to.addAction(action: action)
    }

    // MARK: - Table Config

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 0 ? CGFloat.leastNonzeroMagnitude : 19
    }

    // MARK: - Table Footer Text

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        podcast.overrideGlobalEffects ? nil : L10n.settingsCustomMsg
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }

    // MARK: - Settings changes

    private func playbackSpeedChanged(_ speed: TimeInterval) {
        // round it to the nearest 0.1, so we end up with 1.5 not 1.53667346262
        let roundedSpeed = round(speed * 10.0) / 10.0
        podcast.playbackSpeed = roundedSpeed
        saveUpdates()

        playbackSpeedDebouncer.call {
            AnalyticsPlaybackHelper.shared.currentSource = self.analyticsSource
            AnalyticsPlaybackHelper.shared.playbackSpeedChanged(to: roundedSpeed)
        }
    }

    @objc private func trimSilenceToggled(_ sender: UISwitch) {
        podcast.trimSilenceAmount = sender.isOn ? Int32(PlaybackEffects.defaultRemoveSilenceAmount) : 0
        saveUpdates()
        AnalyticsPlaybackHelper.shared.trimSilenceToggled(enabled: sender.isOn)
    }

    @objc private func boostVolumeToggled(_ sender: UISwitch) {
        podcast.boostVolume = sender.isOn
        saveUpdates()

        AnalyticsPlaybackHelper.shared.volumeBoostToggled(enabled: sender.isOn)
    }

    @objc private func overrideEffectsToggled(_ sender: UISwitch) {
        podcast.overrideGlobalEffects = sender.isOn
        saveUpdates()

        Analytics.track(.podcastSettingsCustomPlaybackEffectsToggled, properties: ["enabled": sender.isOn])
    }

    private func tableData() -> [[TableRow]] {
        if podcast.overrideGlobalEffects, podcast.trimSilenceAmount > 0 {
            return [[.customForPodcast], [.playbackSpeed, .trimSilence, .trimSilenceAmount, .volumeBoost]]
        }

        return [[.customForPodcast], [.playbackSpeed, .trimSilence, .volumeBoost]]
    }

    private func saveUpdates() {
        effectsTable.reloadData()
        DataManager.sharedManager.save(podcast: podcast)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast.uuid)

        // if we're actively playing this episode, let the player know
        if let episode = PlaybackManager.shared.currentEpisode() as? Episode, podcast.uuid == episode.parentIdentifier() {
            PlaybackManager.shared.effectsChangedExternally()
        }
    }
}
