import PocketCastsDataModel
import PocketCastsUtils

extension PlaylistDetailViewModel {
    func playAllEpisodes() {
        PlaybackManager.shared.play(playlist: playlist)
    }

    func saveUpNextAndPlay() {
        Task { [weak self] in
            guard let self else { return }
            let batches = await self.batchedUpNextEpisodes()
            await MainActor.run {
                self.playAllEpisodes()
            }
            let success = await self.createPlaylists(from: batches)
            if success {
                await MainActor.run {
                    Toast.show(
                        batches.count > 1 ? L10n.playlistPlayAllUpNextSavedPlural : L10n.playlistPlayAllUpNextSaved,
                        actions: [
                            .init(title: L10n.bookmarkAddedButtonTitle) {
                                NavigationManager.sharedManager.navigateTo(
                                    NavigationManager.filterPageKey
                                )
                            }
                        ]
                    )
                }
            }
        }
    }

    private func batchedUpNextEpisodes(batchSize: Int = Constants.Limits.maxFilterItems) async -> [[Episode]] {
        let uuids = dataManager.allUpNextEpisodeUuids().compactMap(\.uuid)
        let allEpisodes = dataManager.allUpNextEpisodes(from: uuids)

        guard !allEpisodes.isEmpty else { return [] }
        guard allEpisodes.count > batchSize else { return [allEpisodes] }

        var result: [[Episode]] = []
        var startIndex = 0

        while startIndex < allEpisodes.count {
            let endIndex = min(startIndex + batchSize, allEpisodes.count)
            result.append(Array(allEpisodes[startIndex..<endIndex]))
            startIndex += batchSize
        }

        return result
    }

    private func createPlaylists(from batches: [[Episode]]) async -> Bool {
        let firstSortPosition = max(0, DataManager.sharedManager.firstSortPositionForPlaylist())
        DataManager.sharedManager.bumpSortPositionForAllPlaylists(adding: batches.count)
        for (index, batch) in batches.enumerated() {
            let playlist = newManualPlaylist(index: index + 1, sortPosition: firstSortPosition + index)
            DataManager.sharedManager.save(playlist: playlist)
            DataManager.sharedManager.add(episodes: batch, to: playlist)
        }
        return true
    }

    private func newManualPlaylist(index: Int, sortPosition: Int) -> EpisodeFilter {
        var playlistName = "\(L10n.upNext) - \(Date().monthDayString())"
        if index > 1 {
            playlistName += " (\(index))"
        }
        let playlist = PlaylistManager.createNewPlaylist()
        playlist.setTitle(playlistName, defaultTitle: L10n.playlistsDefaultNewPlaylist.localizedCapitalized)
        playlist.manual = true
        playlist.syncStatus = SyncStatus.notSynced.rawValue
        playlist.isNew = false
        playlist.sortType = PlaylistSort.dragAndDrop.rawValue
        playlist.sortPosition = Int32(sortPosition)
        return playlist
    }
}
