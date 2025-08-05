import SwiftUI
import PocketCastsUtils

extension PodcastListViewController: UIPopoverPresentationControllerDelegate {
    func showRecentlyPlayedSortingTipIfNeeded() {
        guard
            Settings.shouldShowRecentlyPlayedSortingTip,
            FeatureFlag.podcastsSortChanges.enabled,
            recentlyPlayedSortingTip == nil
        else {
            return
        }
        if let vc = showRecentlyPlayedSortingTip() {
            present(vc, animated: true) {
                Analytics.track(.episodeRecentlyPlayedSortOptionTooltipShown)
            }
            recentlyPlayedSortingTip = vc
        }
    }

    private func showRecentlyPlayedSortingTip() -> UIViewController? {
        guard let button = customRightBtn else {
            return nil
        }
        let idealSize = CGSize(width: 300, height: 120)
        let tipView = TipViewStatic(title: L10n.podcastsLibrarySortEpisodeRecentlyPlayedTipTitle,
                                    message: L10n.podcastsLibrarySortEpisodeRecentlyPlayedTipDescription,
                              onTap: { [weak self] in
            self?.dismissRecentlyPlayedSortingTip()
        })
            .frame(maxWidth: idealSize.width, minHeight: idealSize.height)
            .setupDefaultEnvironment()
        let vc = UIHostingController(rootView: tipView)
        vc.view.backgroundColor = .clear
        vc.view.clipsToBounds = false
        vc.modalPresentationStyle = .popover
        vc.sizingOptions = [.preferredContentSize]
        if let popoverPresentationController = vc.popoverPresentationController {
            popoverPresentationController.delegate = self
            popoverPresentationController.permittedArrowDirections = [.up]
            popoverPresentationController.sourceItem = button
            popoverPresentationController.backgroundColor = ThemeColor.primaryUi01()
        }
        return vc
    }

    private func dismissRecentlyPlayedSortingTip() {
        Analytics.track(.episodeRecentlyPlayedSortOptionTooltipDismissed)
        Settings.shouldShowRecentlyPlayedSortingTip = false
        recentlyPlayedSortingTip?.dismiss(animated: true) { [weak self] in
            self?.recentlyPlayedSortingTip = nil
        }
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        dismissRecentlyPlayedSortingTip()
    }
}
