import PocketCastsDataModel

extension PodcastArchiveViewController: UITableViewDataSource, UITableViewDelegate {
    private static let disclosureCellId = "DisclosureCell"
    private static let switchCellId = "SwitchCell"

    private enum TableRow { case customForPodcast, playedEpisodes, inactiveEpisodes, episodeLimit }
    private static let tableData: [[TableRow]] = [[.customForPodcast], [.playedEpisodes, .inactiveEpisodes], [.episodeLimit]]

    func registerCells() {
        archiveTable.register(UINib(nibName: "DisclosureCell", bundle: nil), forCellReuseIdentifier: PodcastArchiveViewController.disclosureCellId)
        archiveTable.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: PodcastArchiveViewController.switchCellId)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        podcast.overrideGlobalArchive ? PodcastArchiveViewController.tableData.count : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        PodcastArchiveViewController.tableData[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableRow = PodcastArchiveViewController.tableData[indexPath.section][indexPath.row]

        switch tableRow {
        case .customForPodcast:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastArchiveViewController.switchCellId, for: indexPath) as! SwitchCell
            cell.cellLabel.text = L10n.settingsCustom
            cell.cellSwitch.onTintColor = podcast.switchTintColor()
            cell.cellSwitch.isOn = podcast.overrideGlobalArchive

            cell.cellSwitch.removeTarget(self, action: #selector(overrideArchiveToggled(_:)), for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(overrideArchiveToggled(_:)), for: UIControl.Event.valueChanged)

            return cell
        case .playedEpisodes:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastArchiveViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.settingsArchivePlayedEpisodes

            let playedValue = podcast.overrideGlobalArchive ? podcast.autoArchivePlayedAfter : Settings.autoArchivePlayedAfter()
            cell.cellSecondaryLabel.text = ArchiveHelper.archiveTimeToText(playedValue)

            return cell
        case .inactiveEpisodes:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastArchiveViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.settingsArchiveInactiveEpisodes

            let inactiveValue = podcast.overrideGlobalArchive ? podcast.autoArchiveInactiveAfter : Settings.autoArchiveInactiveAfter()
            cell.cellSecondaryLabel.text = ArchiveHelper.archiveTimeToText(inactiveValue)

            return cell
        case .episodeLimit:
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastArchiveViewController.disclosureCellId, for: indexPath) as! DisclosureCell
            cell.cellLabel.text = L10n.settingsEpisodeLimit
            cell.cellSecondaryLabel.text = stringForLimit(podcast.autoArchiveEpisodeLimit)

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = PodcastArchiveViewController.tableData[indexPath.section][indexPath.row]

        if row == .playedEpisodes {
            let options = OptionsPicker(title: L10n.settingsArchivePlayedTitle)

            addArchivePlayedAction(time: -1, to: options)
            addArchivePlayedAction(time: 0, to: options)
            addArchivePlayedAction(time: 24.hours, to: options)
            addArchivePlayedAction(time: 2.days, to: options)
            addArchivePlayedAction(time: 1.week, to: options)

            options.show(statusBarStyle: preferredStatusBarStyle)
        } else if row == .inactiveEpisodes {
            let options = OptionsPicker(title: L10n.settingsArchiveInactiveTitle)

            addArchiveInactiveAction(time: -1, to: options)
            addArchiveInactiveAction(time: 24.hours, to: options)
            addArchiveInactiveAction(time: 2.days, to: options)
            addArchiveInactiveAction(time: 1.week, to: options)
            addArchiveInactiveAction(time: 2.weeks, to: options)
            addArchiveInactiveAction(time: 30.days, to: options)
            addArchiveInactiveAction(time: 90.days, to: options)

            options.show(statusBarStyle: preferredStatusBarStyle)
        } else if row == .episodeLimit {
            let options = OptionsPicker(title: L10n.settingsEpisodeLimit)
            addEpisodeLimitAction(limit: 0, to: options)
            addEpisodeLimitAction(limit: 1, to: options)
            addEpisodeLimitAction(limit: 2, to: options)
            addEpisodeLimitAction(limit: 5, to: options)
            addEpisodeLimitAction(limit: 10, to: options)

            options.show(statusBarStyle: preferredStatusBarStyle)
        }
    }

    // MARK: - Table Config

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 0 ? CGFloat.leastNonzeroMagnitude : 19
    }

    // MARK: - Table Footer Text

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let firstRow = PodcastArchiveViewController.tableData[section][0]

        if firstRow == .customForPodcast {
            return podcast.overrideGlobalArchive ? nil : L10n.settingsCustomAutoArchiveMsg
        } else if firstRow == .playedEpisodes {
            return L10n.settingsInactiveEpisodesMsg
        } else if firstRow == .episodeLimit {
            return L10n.settingsEpisodeLimitMsg
        }

        return nil
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }

    // MARK: - Settings changes

    @objc private func overrideArchiveToggled(_ sender: UISwitch) {
        podcast.overrideGlobalArchive = sender.isOn

        if sender.isOn {
            podcast.autoArchivePlayedAfter = Settings.autoArchivePlayedAfter()
            podcast.autoArchiveInactiveAfter = Settings.autoArchiveInactiveAfter()
        }

        DataManager.sharedManager.save(podcast: podcast)

        archiveTable.reloadData()
        archiveSettingsChanged = true
    }

    private func addEpisodeLimitAction(limit: Int32, to: OptionsPicker) {
        let selectedSetting = podcast.autoArchiveEpisodeLimit
        let action = OptionAction(label: stringForLimit(limit), selected: selectedSetting == limit) { [weak self] in
            guard let self = self else { return }

            self.podcast.autoArchiveEpisodeLimit = limit
            DataManager.sharedManager.saveAutoArchiveLimit(podcast: self.podcast, limit: limit)
            DataManager.sharedManager.save(podcast: self.podcast)

            self.archiveTable.reloadData()
            self.archiveSettingsChanged = true
        }
        to.addAction(action: action)
    }

    private func addArchivePlayedAction(time: TimeInterval, to: OptionsPicker) {
        let selectedSetting = podcast.autoArchivePlayedAfter
        let action = OptionAction(label: ArchiveHelper.archiveTimeToText(time), selected: selectedSetting == time) { [weak self] in
            guard let self = self else { return }

            self.podcast.autoArchivePlayedAfter = time
            DataManager.sharedManager.save(podcast: self.podcast)

            self.archiveTable.reloadData()
            self.archiveSettingsChanged = true
        }
        to.addAction(action: action)
    }

    private func addArchiveInactiveAction(time: TimeInterval, to: OptionsPicker) {
        let selectedSetting = podcast.autoArchiveInactiveAfter
        let action = OptionAction(label: ArchiveHelper.archiveTimeToText(time), selected: selectedSetting == time) { [weak self] in
            guard let self = self else { return }

            self.podcast.autoArchiveInactiveAfter = time
            DataManager.sharedManager.save(podcast: self.podcast)

            self.archiveTable.reloadData()
            self.archiveSettingsChanged = true
        }
        to.addAction(action: action)
    }

    private func stringForLimit(_ limit: Int32) -> String {
        limit == 0 ? L10n.settingsEpisodeLimitNoLimit : L10n.settingsEpisodeLimitLimitFormat(limit.localized())
    }
}
