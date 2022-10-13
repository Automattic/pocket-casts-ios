import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

extension ListeningHistoryViewController: MultiSelectActionDelegate {
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
        multiSelectFooter.setStatus(status: status)
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

    var multiSelectViewSource: AnalyticsSource {
        analyticsSource
    }

    // MARK: - Selected Episode

    func selectedEpisodesContains(uuid: String) -> Bool {
        selectedEpisodes.contains { $0.episode.uuid == uuid }
    }

    func selectedEpisodesRemove(uuid: String) {
        if let currentEpisodeIndex = selectedEpisodes.firstIndex(where: { $0.episode.uuid == uuid }) {
            selectedEpisodes.remove(at: currentEpisodeIndex)
        }
    }

    @IBAction func selectAllTapped() {
        let shouldSelectAll = MultiSelectHelper.shouldSelectAll(onCount: selectedEpisodes.count, totalCount: episodeCount())

        Analytics.track(.listeningHistorySelectAllButtonTapped, properties: ["select_all": shouldSelectAll])

        if shouldSelectAll {
            listeningHistoryTable.selectAll()
        } else {
            listeningHistoryTable.deselectAll()
        }
        updateSelectAllBtn()
    }

    @IBAction func cancelTapped() {
        isMultiSelectEnabled = false
    }

    func updateSelectAllBtn() {
        guard isMultiSelectEnabled else { return }
        let leftButtonTitle = MultiSelectHelper.shouldSelectAll(onCount: selectedEpisodes.count, totalCount: episodeCount()) ? L10n.selectAll : L10n.deselectAll
        if navigationItem.leftBarButtonItem?.title != leftButtonTitle {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: leftButtonTitle, style: .done, target: self, action: #selector(selectAllTapped))
        }
    }

    func episodeCount() -> Int {
        var count = 0
        episodes.forEach { count = count + $0.elements.count }
        return count
    }
}
