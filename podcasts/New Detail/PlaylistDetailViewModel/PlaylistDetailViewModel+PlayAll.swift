import PocketCastsDataModel
import PocketCastsUtils

extension PlaylistDetailViewModel {
    func playAllEpisodes() {
        PlaybackManager.shared.play(playlist: playlist)
    }

    func saveUpNextAndPlay() {
        let dataManager = dataManager
        Task.detached { [weak self] in
            guard let self else { return }
            let uuids = dataManager.allUpNextEpisodeUuids().compactMap(\.uuid)
            let episodes = dataManager.allUpNextEpisodes(from: uuids)
            await MainActor.run {
                self.playAllEpisodes()
            }
            let baseName = "\(L10n.upNext) - \(Date().monthDayString())"
            let created = dataManager.createManualPlaylists(from: episodes, batchSize: Constants.Limits.maxFilterItems, baseName: baseName)
            if created > 0 {
                await MainActor.run {
                    Toast.show(
                        created > 1 ? L10n.playlistPlayAllUpNextSavedPlural : L10n.playlistPlayAllUpNextSaved,
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
}
