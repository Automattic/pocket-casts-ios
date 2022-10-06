import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

extension StarredViewController: MultiSelectActionDelegate {
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
        let shouldSelectAll = MultiSelectHelper.shouldSelectAll(onCount: selectedEpisodes.count, totalCount: episodes.count)

        Analytics.track(.starredSelectAllButtonTapped, properties: ["select_all": shouldSelectAll])

        if shouldSelectAll {
            starredTable.selectAll()
        } else {
            starredTable.deselectAll()
        }
        updateSelectAllBtn()
    }

    @IBAction func cancelTapped() {
        isMultiSelectEnabled = false
    }

    @IBAction func selectTapped() {
        isMultiSelectEnabled = true
    }

    func updateSelectAllBtn() {
        guard isMultiSelectEnabled else { return }
        let leftButtonTitle = MultiSelectHelper.shouldSelectAll(onCount: selectedEpisodes.count, totalCount: episodes.count) ? L10n.selectAll : L10n.deselectAll
        if navigationItem.leftBarButtonItem?.title != leftButtonTitle {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: leftButtonTitle, style: .done, target: self, action: #selector(selectAllTapped))
        }
    }
}
