import PocketCastsDataModel
import PocketCastsServer

extension UserEpisodeDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func registerCells() {
        actionTable.register(UINib(nibName: "UserEpisodeActionCell", bundle: nil), forCellReuseIdentifier: actionCellId)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = actionTable.dequeueReusableCell(withIdentifier: actionCellId) as! UserEpisodeActionCell
        cell.themeOverride = themeOverride
        cell.titleLabel.themeOverride = themeOverride
        cell.style = .primaryUi01
        let tableRow = tableData()[indexPath.row]

        switch tableRow {
        case .download:
            cell.titleLabel.text = L10n.download
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = UIImage(named: "episode-download")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        case .cancelDownload:
            cell.titleLabel.text = L10n.cancelDownload
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = UIImage(named: "cancel")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        case .upload:
            cell.titleLabel.text = L10n.customEpisodeUpload
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = UIImage(named: "plus_upload")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
            cell.setLocked(locked: !SubscriptionHelper.hasActiveSubscription())
        case .removeFromCloud:
            cell.titleLabel.text = L10n.customEpisodeRemoveUpload
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = UIImage(named: "remove_from_cloud")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        case .upNext:
            cell.titleLabel.text = PlaybackManager.shared.inUpNext(episode: episode) ? L10n.removeFromUpNext : L10n.addToUpNext
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = PlaybackManager.shared.inUpNext(episode: episode) ? UIImage(named: "episode-removenext") : UIImage(named: "episode-playnext")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        case .markAsPlayed:
            cell.titleLabel.text = episode.played() ? L10n.markUnplayedShort : L10n.markPlayed
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = episode.played() ? UIImage(named: "episode-markunplayed") : UIImage(named: "episode-markasplayed")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        case .editDetails:
            cell.titleLabel.text = L10n.edit
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = UIImage(named: "rename")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        case .delete:
            cell.titleLabel.text = L10n.delete
            cell.titleLabel.style = .support05
            cell.actionImage?.image = UIImage(named: "delete")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        case .cancelUpload:
            cell.titleLabel.text = L10n.customEpisodeCancelUpload
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = UIImage(named: "cancel")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()

        case .bookmarks:
            cell.titleLabel.text = L10n.bookmarks
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = UIImage(named: "bookmarks-shelf-overflow-icon")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tableRow = tableData()[indexPath.row]

        switch tableRow {
        case .bookmarks:
            delegate?.showBookmarks(userEpisode: episode)
            animateOut()

        case .download:
            Analytics.track(.userFileDetailOptionTapped, properties: ["option": "download"])
            PlaybackActionHelper.download(episodeUuid: episode.uuid)
            animateOut()
        case .cancelDownload:
            Analytics.track(.userFileDetailOptionTapped, properties: ["option": "cancel_download"])
            PlaybackActionHelper.stopDownload(episodeUuid: episode.uuid)
            animateOut()
        case .upload:
            if SubscriptionHelper.hasActiveSubscription() {
                Analytics.track(.userFileDetailOptionTapped, properties: ["option": "upload"])
                PlaybackActionHelper.upload(episodeUuid: episode.uuid)
                animateOut()
            } else {
                animateOut()
                delegate?.showUpgradeRequired()
                Analytics.track(.userFileDetailOptionTapped, properties: ["option": "upload_upgrade_required"])
            }
        case .cancelUpload:
            PlaybackActionHelper.stopUpload(episodeUuid: episode.uuid)
            Analytics.track(.userFileDetailOptionTapped, properties: ["option": "cancel_upload"])
            animateOut()
        case .removeFromCloud:
            UserEpisodeManager.deleteFromCloud(episode: episode)
            Analytics.track(.userFileDetailOptionTapped, properties: ["option": "delete_from_cloud"])
            animateOut()
        case .upNext:
            if PlaybackManager.shared.inUpNext(episode: episode) {
                Analytics.track(.userFileDetailOptionTapped, properties: ["option": "up_next_delete"])
                PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true, userInitiated: true)
            } else {
                let addToUpNextPicker = OptionsPicker(title: L10n.addToUpNext.localizedUppercase)
                let playNextAction = OptionAction(label: L10n.playNext, icon: "list_playnext") {
                    Analytics.track(.userFileDetailOptionTapped, properties: ["option": "up_next_add_top"])
                    PlaybackManager.shared.addToUpNext(episode: self.episode, ignoringQueueLimit: true, toTop: true, userInitiated: true)
                }
                addToUpNextPicker.addAction(action: playNextAction)

                let playLastAction = OptionAction(label: L10n.playLast, icon: "list_playlast") {
                    Analytics.track(.userFileDetailOptionTapped, properties: ["option": "up_next_add_bottom"])
                    PlaybackManager.shared.addToUpNext(episode: self.episode, ignoringQueueLimit: true, toTop: false)
                }
                addToUpNextPicker.addAction(action: playLastAction)

                addToUpNextPicker.show(statusBarStyle: preferredStatusBarStyle)
            }
            animateOut()
        case .markAsPlayed:
            AnalyticsEpisodeHelper.shared.currentSource = analyticsSource

            if episode.played() {
                Analytics.track(.userFileDetailOptionTapped, properties: ["option": "mark_unplayed"])
                EpisodeManager.markAsUnplayed(episode: episode, fireNotification: true)
            } else {
                Analytics.track(.userFileDetailOptionTapped, properties: ["option": "mark_played"])
                EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
            }
            animateOut()
        case .editDetails:
            animateOut()
            delegate?.showEdit(userEpisode: episode)
            Analytics.track(.userFileDetailOptionTapped, properties: ["option": "edit"])
        case .delete:
            animateOut()
            delegate?.showDeleteConfirmation(userEpisode: episode)
            Analytics.track(.userFileDetailOptionTapped, properties: ["option": "delete"])
        }
    }

    private func tableData() -> [TableRow] {
        var data: [TableRow] = [.upNext, .markAsPlayed, .bookmarks, .editDetails, .delete]

        if episode.queued() || episode.downloading() || episode.waitingForWifi() {
            data.insert(.cancelDownload, at: 3)
        } else if episode.uploadQueued() || episode.uploading() || episode.uploadWaitingForWifi() {
            data.insert(.cancelUpload, at: 3)
        } else if !episode.downloaded(pathFinder: DownloadManager.shared) {
            data.insert(.download, at: 3)
        } else if episode.uploaded() {
            data.insert(.removeFromCloud, at: 3)
        } else {
            data.insert(.upload, at: 3)
        }
        return data
    }

    // MARK: Actions

    @IBAction func playPauseTapped(_ sender: UIButton) {
        playPauseButton.isPlaying = !playPauseButton.isPlaying

        let option = playPauseButton.isPlaying ? "play" : "pause"
        Analytics.track(.userFilePlayPauseButtonTapped, properties: ["option": option])

        if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid) {
            // dismiss the dialog if the user hit play
            if !PlaybackManager.shared.playing() {
                animateOut()
            }

            PlaybackActionHelper.playPause()
        } else {
            PlaybackActionHelper.play(episode: episode, playlist: playlist)
            animateOut()
        }
    }
}
