import PocketCastsDataModel

import PocketCastsServer
import PocketCastsUtils
import UIKit

extension PodcastViewController {
    // MARK: - MultiSelect action delegate

    func multiSelectPresentingViewController() -> UIViewController {
        self
    }

    func multiSelectedBaseEpisodes() -> [BaseEpisode] {
        selectedEpisodes.map(\.episode)
    }

    func multiSelectedPlayListEpisodes() -> [PlaylistEpisode]? {
        nil
    }

    func multiSelectActionBegan(status: String) {
        DispatchQueue.main.async {
            self.multiSelectFooter.setStatus(status: status)
        }
    }

    func multiSelectActionCompleted() {
        DispatchQueue.main.async {
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
                self.multiSelectFooterBottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.isMultiSelectEnabled = false
            })
        }
    }

    func multiSelectPreferredStatusBarStyle() -> UIStatusBarStyle {
        preferredStatusBarStyle
    }

    // MARK: - Selected Episode

    func selectedEpisodesContains(uuid: String) -> Bool {
        let selectedUuids = selectedEpisodes.map(\.episode.uuid)
        return selectedUuids.contains(uuid)
    }

    func selectedEpisodesRemove(uuid: String) {
        let selectedUuids = selectedEpisodes.map(\.episode.uuid)
        if let currentEpisodeIndex = selectedUuids.firstIndex(of: uuid) {
            selectedEpisodes.remove(at: currentEpisodeIndex)
        }
    }

    @IBAction func selectAllTapped() {
        let shouldSelectAll = multiSelectAllBtn.title(for: .normal) == L10n.selectAll
        if shouldSelectAll {
            guard let allObjects = episodeInfo[safe: 1]?.elements, allObjects.count > 0 else { return }
            episodesTable.selectAllBelow(indexPath: IndexPath(row: 0, section: PodcastViewController.allEpisodesSection))
        } else {
            episodesTable.deselectAll()
            if selectedEpisodes.count != 0 { // special case where hidden (archived) episodes are selected
                selectedEpisodes.removeAll()
            }
        }
        updateSelectAllBtn()
    }

    @IBAction func cancelTapped() {
        isMultiSelectEnabled = false
    }

    func updateSelectAllBtn() {
        let episodesInTable = episodeInfo[PodcastViewController.allEpisodesSection].elements.compactMap { $0 as? ListEpisode }.count
        if MultiSelectHelper.shouldSelectAll(onCount: selectedEpisodes.count, totalCount: episodesInTable) {
            multiSelectAllBtn.setTitle(L10n.selectAll, for: .normal)
        } else {
            multiSelectAllBtn.setTitle(L10n.deselectAll, for: .normal)
        }
    }

    func selectAllAbove(indexPath: IndexPath) {
        guard indexPath.section == PodcastViewController.allEpisodesSection else { return }
        episodesTable.selectAllFrom(fromIndexPath: IndexPath(row: 0, section: PodcastViewController.allEpisodesSection), toIndexPath: indexPath)
    }

    func selectAllBelow(indexPath: IndexPath) {
        guard indexPath.section == PodcastViewController.allEpisodesSection else { return }
        episodesTable.selectAllBelow(indexPath: indexPath)
    }
}
