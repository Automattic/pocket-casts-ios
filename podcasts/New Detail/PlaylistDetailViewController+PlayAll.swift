extension PlaylistDetailViewController: UISheetPresentationControllerDelegate, PlaylistPlayAllSheetHostDelegate {
    func playAll() {
        if viewModel.episodes.isEmpty {
            Toast.show(L10n.playlistManualPlayAllEmptyList)
            return
        }

        track(.filterPlayAllTapped)

        Task { [weak self] in
            guard let self else { return }
            let hasDifferencesWithUpNext = await self.checkDifferencesWithUpNext()
            if hasDifferencesWithUpNext {
                await MainActor.run {
                    let sheet = PlaylistPlayAllSheetHost(delegate: self)
                    self.present(sheet, animated: true)
                }
            } else if !PlaybackManager.shared.playing() {
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.playbackStarting)
                PlaybackManager.shared.play()
            }
        }
    }

    private func checkDifferencesWithUpNext() async -> Bool {
        let playlistEpisodeUuids = viewModel.episodes.map { $0.episode.uuid }
        let upNextEpisodeUuids = viewModel.dataManager.allUpNextEpisodeUuids().compactMap(\.uuid)

        if playlistEpisodeUuids.count != upNextEpisodeUuids.count {
            return true
        }

        if playlistEpisodeUuids != upNextEpisodeUuids {
            return true
        }

        guard let firstPlaylistUuid = playlistEpisodeUuids.first else {
            return false
        }

        guard let currentUuid = PlaybackManager.shared.currentEpisode()?.uuid else {
            return true
        }

        return currentUuid != firstPlaylistUuid
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        track(.filterPlayAllDismissed)
    }

    func onTapSaveAndReplace() {
        presentedViewController?.dismiss(animated: true)

        if PlaybackManager.shared.queue.upNextCount() == 0 {
            // there's nothing to over-write, so nothing to confirm either
            viewModel.playAllEpisodes()
            return
        }

        track(
            .filterPlayAllReplaceAndPlayTapped,
            properties: [
                "save_up_next": Settings.saveCurrentUpNextQueueIntoPlaylist
            ]
        )

        if Settings.saveCurrentUpNextQueueIntoPlaylist {
            viewModel.saveUpNextAndPlay()
            return
        }

        viewModel.playAllEpisodes()
    }
}
