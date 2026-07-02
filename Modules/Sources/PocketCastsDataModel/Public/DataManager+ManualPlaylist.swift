import Foundation

public extension DataManager {
    /// Splits `episodes` into batches of `batchSize` and saves each batch as a new manual playlist.
    /// Playlists are named `baseName`, with a ` (2)`, ` (3)`… suffix when more than one is created.
    /// Returns the number of playlists created.
    @discardableResult
    func createManualPlaylists(from episodes: [Episode], batchSize: Int, baseName: String) -> Int {
        guard !episodes.isEmpty, batchSize > 0 else { return 0 }

        var batches: [[Episode]] = []
        var startIndex = 0
        while startIndex < episodes.count {
            let endIndex = min(startIndex + batchSize, episodes.count)
            batches.append(Array(episodes[startIndex..<endIndex]))
            startIndex += batchSize
        }

        let firstSortPosition = max(0, firstSortPositionForPlaylist())
        bumpSortPositionForAllPlaylists(adding: batches.count)

        for (index, batch) in batches.enumerated() {
            let name = index > 0 ? "\(baseName) (\(index + 1))" : baseName
            let playlist = Self.manualPlaylist(named: name, sortPosition: firstSortPosition + index)
            save(playlist: playlist)
            _ = add(episodes: batch, to: playlist)
        }

        return batches.count
    }

    private static func manualPlaylist(named name: String, sortPosition: Int) -> EpisodeFilter {
        let playlist = EpisodeFilter()
        playlist.uuid = UUID().uuidString
        playlist.playlistName = name
        playlist.manual = true
        playlist.syncStatus = SyncStatus.notSynced.rawValue
        playlist.isNew = false
        playlist.sortType = PlaylistSort.dragAndDrop.rawValue
        playlist.sortPosition = Int32(sortPosition)
        playlist.filterAllPodcasts = true
        playlist.filterUnplayed = true
        playlist.filterPartiallyPlayed = true
        playlist.filterFinished = true
        playlist.filterDownloaded = true
        playlist.filterNotDownloaded = true
        playlist.filterAudioVideoType = AudioVideoFilter.all.rawValue
        return playlist
    }
}
