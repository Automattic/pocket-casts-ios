import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

extension UploadedViewController: MultiSelectActionDelegate {
    // MARK: - MultiSelect action delegate

    func multiSelectPresentingViewController() -> UIViewController {
        self
    }

    func multiSelectedBaseEpisodes() -> [BaseEpisode] {
        selectedEpisodes.map { $0 as BaseEpisode }
    }

    func multiSelectedPlayListEpisodes() -> [PlaylistEpisode]? {
        nil
    }

    func multiSelectActionBegan(status: String) {
        multiSelectActionBar.setStatus(status: status)
    }

    func multiSelectActionCompleted() {
        DispatchQueue.main.async {
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
                self.multiSelectActionBarBottomConstraint.constant = 0
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
        selectedEpisodes.contains { $0.uuid == uuid }
    }

    func selectedEpisodesRemove(uuid: String) {
        if let currentEpisodeIndex = selectedEpisodes.firstIndex(where: { $0.uuid == uuid }) {
            selectedEpisodes.remove(at: currentEpisodeIndex)
        }
    }

    @IBAction func selectAllTapped() {
        let shouldSelectAll = MultiSelectHelper.shouldSelectAll(onCount: selectedEpisodes.count, totalCount: uploadedEpisodes.count)

        Analytics.track(.uploadedFilesSelectAllButtonTapped, properties: ["select_all": shouldSelectAll])

        if shouldSelectAll {
            uploadsTable.selectAll()
        } else {
            uploadsTable.deselectAll()
        }
        updateSelectAllBtn()
    }

    @IBAction func cancelTapped() {
        isMultiSelectEnabled = false
    }

    func updateSelectAllBtn() {
        guard isMultiSelectEnabled else { return }
        let leftButtonTitle = MultiSelectHelper.shouldSelectAll(onCount: selectedEpisodes.count, totalCount: uploadedEpisodes.count) ? L10n.selectAll : L10n.deselectAll
        if navigationItem.leftBarButtonItem?.title != leftButtonTitle {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: leftButtonTitle, style: .done, target: self, action: #selector(selectAllTapped))
        }
    }
}
