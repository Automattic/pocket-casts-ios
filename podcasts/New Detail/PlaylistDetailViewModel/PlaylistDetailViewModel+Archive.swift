import PocketCastsDataModel

extension PlaylistDetailViewModel {
    var shouldShowArchived: Bool {
        playlist.showArchivedEpisodes
    }

    var shouldShowArchivePlaceholder: Bool {
        archivedEpisodesCount > 0 && !shouldShowArchived
    }

    var shouldShowEmptyPlaceholder: Bool {
        episodes.isEmpty && !shouldShowArchivePlaceholder
    }

    func unarchivedEpisodesCount() -> Int {
        dataManager.playlistEpisodeCount(
            for: playlist,
            episodeUuidToAdd: playlist.episodeUuidToAddToQueries()
        )
    }

    func updateShowArchivedEpisodes(show: Bool) {
        playlist.showArchivedEpisodes = show
        dataManager.save(playlist: playlist)
    }
}
