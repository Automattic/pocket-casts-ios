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

    var archivedEpisodesCount: Int {
        dataManager.playlistEpisodeCount(
            for: playlist,
            episodeUuidToAdd: playlist.episodeUuidToAddToQueries(),
            shouldShowArchived: true
        )
    }

    func unarchivedEpisodesCount() -> Int {
        return episodesCount
    }

    func updateShowArchivedEpisodes(show: Bool) {
        playlist.showArchivedEpisodes = show
        dataManager.save(playlist: playlist)
    }
}
