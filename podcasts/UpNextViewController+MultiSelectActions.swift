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

    // MARK: - Long Press Multi Select Option Picker

    func showLongPressSelectOptions(indexPath: IndexPath) {
        let optionPicker = OptionsPicker(title: nil, themeOverride: themeOverride, iconTintStyle: .primaryIcon02)

        let allAboveAction = OptionAction(label: L10n.selectAllAbove, icon: "selectall-up", action: { [] in
            self.upNextTable.selectAllFrom(fromIndexPath: IndexPath(row: 0, section: UpNextViewController.upNextSection), toIndexPath: indexPath)

        })
        let allBelowAction = OptionAction(label: L10n.selectAllBelow, icon: "selectall-down", action: { [] in
            self.upNextTable.selectAllBelow(indexPath: indexPath)
        })
        optionPicker.addAction(action: allAboveAction)
        optionPicker.addAction(action: allBelowAction)
        optionPicker.show(statusBarStyle: preferredStatusBarStyle)
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
