import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

extension UpNextViewController: MultiSelectActionDelegate {
    func multiSelectPresentingViewController() -> UIViewController {
        self
    }

    func multiSelectedBaseEpisodes() -> [BaseEpisode] {
        selectedPlayListEpisodes.compactMap { DataManager.sharedManager.findBaseEpisode(uuid: $0.episodeUuid) }
    }

    func multiSelectedPlayListEpisodes() -> [PlaylistEpisode]? {
        selectedPlayListEpisodes
    }

    func multiSelectActionBegan(status: String) {
        multiSelectActionBar.setStatus(status: status)
    }

    func multiSelectActionCompleted() {
        isMultiSelectEnabled = false
    }

    func multiSelectPreferredStatusBarStyle() -> UIStatusBarStyle {
        preferredStatusBarStyle
    }

    var multiSelectViewSource: AnalyticsSource {
        analyticsSource
    }

    // MARK: - Long Press Multi Select Option Picker

    func showLongPressSelectOptions(indexPath: IndexPath) {
        longPressSelectOptions(
            for: indexPath,
            in: upNextTable,
            themeOverride: themeOverride
        )
    }

    // MARK: - Selected Episode

    func selectedEpisodesContains(uuid: String) -> Bool {
        let selectedUuids = selectedPlayListEpisodes.map(\.episodeUuid)
        return selectedUuids.contains(uuid)
    }

    func selectedEpisodesContainsUserEpisode() -> Bool {
        for episode in selectedPlayListEpisodes {
            if episode.isUserEpisode() {
                return true
            }
        }
        return false
    }

    func selectedEpisodesRemove(uuid: String) {
        let selectedUuids = selectedPlayListEpisodes.map(\.episodeUuid)
        if let currentEpisodeIndex = selectedUuids.firstIndex(of: uuid) {
            selectedPlayListEpisodes.remove(at: currentEpisodeIndex)
        }
    }
}
