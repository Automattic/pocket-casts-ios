import PocketCastsDataModel
import PocketCastsUtils

extension PlaylistDetailViewModel {
    func playAllEpisodes() {
        PlaybackManager.shared.play(playlist: playlist)
    }

    func saveUpNextAndPlay() {
        Task { [weak self] in
            guard let self else { return }
            let episodes = self.currentUpNextEpisodes()
            await MainActor.run {
                self.playAllEpisodes()
            }
            let baseName = "\(L10n.upNext) - \(Date().monthDayString())"
            let created = self.dataManager.createManualPlaylists(from: episodes, batchSize: Constants.Limits.maxFilterItems, baseName: baseName)
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

    private func currentUpNextEpisodes() -> [Episode] {
        let uuids = dataManager.allUpNextEpisodeUuids().compactMap(\.uuid)
        return dataManager.allUpNextEpisodes(from: uuids)
    }
}
