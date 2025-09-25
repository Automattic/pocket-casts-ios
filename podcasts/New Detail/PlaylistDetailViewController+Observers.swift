import PocketCastsServer

extension PlaylistDetailViewController {
    func addObservers() {
        addCustomObserver(ServerNotifications.podcastsRefreshed, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.opmlImportCompleted, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeDownloaded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackFailed, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playlistChanged, selector: #selector(refreshFilterFromNotification))
        addCustomObserver(Constants.Notifications.upNextEpisodeRemoved, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.upNextEpisodeAdded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.upNextQueueChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeArchiveStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeStarredChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(UIResponder.keyboardWillShowNotification, selector: #selector(keyboardWillShow(_:)))
        addCustomObserver(UIResponder.keyboardWillHideNotification, selector: #selector(keyboardWillHide(_:)))
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        adjustTextViewForKeyboard(notification: notification, show: true)
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        adjustTextViewForKeyboard(notification: notification, show: false)
    }

    private func adjustTextViewForKeyboard(notification: Notification, show: Bool) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let keyboardHeight = keyboardFrame.height
        keyBoardHeight = (show ? keyboardHeight - (view.distanceFromBottom() ?? 0) : 0)
    }
}
