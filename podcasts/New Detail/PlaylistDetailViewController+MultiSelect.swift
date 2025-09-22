import UIKit
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

extension PlaylistDetailViewController: MultiSelectActionDelegate {
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
            multiSelectActionInProgress = true
            multiSelectFooter.setStatus(status: status)
        }

        func multiSelectActionCompleted() {
            DispatchQueue.main.async {
                self.view.layoutIfNeeded()
                UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
                    self.multiSelectFooterBottomConstraint.constant = 0
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    self.multiSelectActionInProgress = false
                    self.isMultiSelectEnabled = false
                })
            }
        }

        func multiSelectPreferredStatusBarStyle() -> UIStatusBarStyle {
            preferredStatusBarStyle
        }

        var multiSelectViewSource: AnalyticsSource {
            analyticsSource
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

        func updateSelectAllBtn() {
            guard isMultiSelectEnabled else { return }
            let leftButtonTitle = MultiSelectHelper.shouldSelectAll(onCount: selectedEpisodes.count, totalCount: viewModel.episodes.count) ? L10n.selectAll : L10n.deselectAll
            multiSelectAllBtn.setTitle(leftButtonTitle, for: .normal)
        }

        @objc func selectAllTapped() {
            let shouldSelectAll = MultiSelectHelper.shouldSelectAll(onCount: selectedEpisodes.count, totalCount: viewModel.episodes.count)

            Analytics.track(.filterSelectAllButtonTapped, properties: ["select_all": shouldSelectAll])

            if shouldSelectAll {
                tableView.selectAll()
            } else {
                tableView.deselectAll()
            }
            updateSelectAllBtn()
        }

        @objc func cancelTapped() {
            isMultiSelectEnabled = false
        }

        func refreshMultiSelectEpisodes() {
            guard isMultiSelectEnabled, !multiSelectActionInProgress else { return }

            let selectedEpisodesInUpdatedEpisodes = selectedEpisodes.filter { viewModel.episodes.contains($0) }
            selectedEpisodes.removeAll()
            selectedEpisodes.append(contentsOf: selectedEpisodesInUpdatedEpisodes)
            multiSelectFooter.setSelectedCount(count: selectedEpisodes.count)
        }
}
