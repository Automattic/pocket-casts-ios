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
            cell.titleLabel.text = L10n.Localizable.download
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = UIImage(named: "episode-download")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        case .cancelDownload:
            cell.titleLabel.text = L10n.Localizable.cancelDownload
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = UIImage(named: "cancel")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        case .upload:
            cell.titleLabel.text = L10n.Localizable.customEpisodeUpload
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = UIImage(named: "plus_upload")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
            cell.setLocked(locked: !SubscriptionHelper.hasActiveSubscription())
        case .removeFromCloud:
            cell.titleLabel.text = L10n.Localizable.customEpisodeRemoveUpload
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = UIImage(named: "remove_from_cloud")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        case .upNext:
            cell.titleLabel.text = PlaybackManager.shared.inUpNext(episode: episode) ? L10n.Localizable.removeFromUpNext : L10n.Localizable.addToUpNext
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = PlaybackManager.shared.inUpNext(episode: episode) ? UIImage(named: "episode-removenext") : UIImage(named: "episode-playnext")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        case .markAsPlayed:
            cell.titleLabel.text = episode.played() ? L10n.Localizable.markUnplayedShort : L10n.Localizable.markPlayed
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = episode.played() ? UIImage(named: "episode-markunplayed") : UIImage(named: "episode-markasplayed")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        case .editDetails:
            cell.titleLabel.text = L10n.Localizable.edit
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = UIImage(named: "rename")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        case .delete:
            cell.titleLabel.text = L10n.Localizable.delete
            cell.titleLabel.style = .support05
            cell.actionImage?.image = UIImage(named: "delete")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        case .cancelUpload:
            cell.titleLabel.text = L10n.Localizable.customEpisodeCancelUpload
            cell.titleLabel.style = .primaryText01
            cell.actionImage?.image = UIImage(named: "cancel")
            cell.actionImage?.tintColor = ThemeColor.primaryIcon01()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tableRow = tableData()[indexPath.row]
        
        switch tableRow {
        case .download:
            PlaybackActionHelper.download(episodeUuid: episode.uuid)
            animateOut()
        case .cancelDownload:
            PlaybackActionHelper.stopDownload(episodeUuid: episode.uuid)
            animateOut()
        case .upload:
            if SubscriptionHelper.hasActiveSubscription() {
                PlaybackActionHelper.upload(episodeUuid: episode.uuid)
                animateOut()
            }
            else {
                animateOut()
                delegate?.showUpgradeRequired()
            }
        case .cancelUpload:
            PlaybackActionHelper.stopUpload(episodeUuid: episode.uuid)
            animateOut()
        case .removeFromCloud:
            UserEpisodeManager.deleteFromCloud(episode: episode)
            animateOut()
        case .upNext:
            if PlaybackManager.shared.inUpNext(episode: episode) {
                PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true)
            }
            else {
                let addToUpNextPicker = OptionsPicker(title: L10n.Localizable.addToUpNext.localizedUppercase)
                let playNextAction = OptionAction(label: L10n.Localizable.playNext, icon: "list_playnext") {
                    PlaybackManager.shared.addToUpNext(episode: self.episode, ignoringQueueLimit: true, toTop: true)
                }
                addToUpNextPicker.addAction(action: playNextAction)
                
                let playLastAction = OptionAction(label: L10n.Localizable.playLast, icon: "list_playlast") {
                    PlaybackManager.shared.addToUpNext(episode: self.episode, ignoringQueueLimit: true, toTop: false)
                }
                addToUpNextPicker.addAction(action: playLastAction)
                
                addToUpNextPicker.show(statusBarStyle: preferredStatusBarStyle)
            }
            animateOut()
        case .markAsPlayed:
            if episode.played() {
                EpisodeManager.markAsUnplayed(episode: episode, fireNotification: true)
            }
            else {
                EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
            }
            animateOut()
        case .editDetails:
            animateOut()
            delegate?.showEdit(userEpisode: episode)
        case .delete:
            animateOut()
            delegate?.showDeleteConfirmation(userEpisode: episode)
        }
    }
    
    private func tableData() -> [TableRow] {
        var data: [TableRow] = [.upNext, .markAsPlayed, .editDetails, .delete]
        
        if episode.queued() || episode.downloading() || episode.waitingForWifi() {
            data.insert(.cancelDownload, at: 3)
        }
        else if episode.uploadQueued() || episode.uploading() || episode.uploadWaitingForWifi() {
            data.insert(.cancelUpload, at: 3)
        }
        else if !episode.downloaded(pathFinder: DownloadManager.shared) {
            data.insert(.download, at: 3)
        }
        else if episode.uploaded() {
            data.insert(.removeFromCloud, at: 3)
        }
        else {
            data.insert(.upload, at: 3)
        }
        return data
    }
    
    // MARK: Actions
    
    @IBAction func playPauseTapped(_ sender: UIButton) {
        playPauseButton.isPlaying = !playPauseButton.isPlaying
        if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid) {
            // dismiss the dialog if the user hit play
            if !PlaybackManager.shared.playing() {
                animateOut()
            }
            
            PlaybackActionHelper.playPause()
        }
        else {
            PlaybackActionHelper.play(episode: episode)
            animateOut()
        }
    }
}
