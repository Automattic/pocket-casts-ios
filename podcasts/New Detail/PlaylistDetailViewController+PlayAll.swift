extension PlaylistDetailViewController: UISheetPresentationControllerDelegate, PlaylistPlayAllSheetHostDelegate {
    func playAll() {
        if viewModel.episodes.isEmpty {
            Toast.show(L10n.playlistManualPlayAllEmptyList)
            return
        }

        track(.filterPlayAllTapped)

        let playlistEpisodeIDs = viewModel.episodes.map { $0.episode.uuid }
        switch PlaybackManager.shared.playAllAction(forPlaylistEpisodeIDs: playlistEpisodeIDs) {
        case .play:
            viewModel.playAllEpisodes()
        case .confirmReplaceUpNext:
            let sheet = PlaylistPlayAllSheetHost(delegate: self)
            present(sheet, animated: true)
        case .resumeCurrent:
            PlaybackManager.shared.resumeIfPaused()
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        track(.filterPlayAllDismissed)
    }

    func onTapSaveAndReplace() {
        presentedViewController?.dismiss(animated: true)

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
