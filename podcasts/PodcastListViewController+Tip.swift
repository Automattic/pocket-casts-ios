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
        let vc = UIHostingController(rootView: AnyView (EmptyView()) )
        let idealSize = CGSizeMake(290, 100)
        let tipView = TipViewStatic(title: L10n.podcastsLibrarySortEpisodeRecentlyPlayedTipTitle,
                                    message: L10n.podcastsLibrarySortEpisodeRecentlyPlayedTipDescription,
                                    showClose: true,
                              onTap: { [weak self] in
            self?.dismissRecentlyPlayedSortingTip()
        })
            .frame(idealWidth: idealSize.width, minHeight: idealSize.height)
            .setupDefaultEnvironment()
        vc.rootView = AnyView(tipView)
        vc.view.backgroundColor = .clear
        vc.view.clipsToBounds = false
        vc.modalPresentationStyle = .popover
        if #available(iOS 16.0, *) {
            vc.sizingOptions = [.preferredContentSize]
        } else {
            vc.preferredContentSize = idealSize
        }
        if let popoverPresentationController = vc.popoverPresentationController {
            popoverPresentationController.delegate = self
            popoverPresentationController.permittedArrowDirections = [.up]
            if #available(iOS 16.0, *) {
                popoverPresentationController.sourceItem = button
            } else {
                popoverPresentationController.barButtonItem = button
            }
            popoverPresentationController.backgroundColor = ThemeColor.primaryUi01()
        }
        return vc
    }

    private func dismissRecentlyPlayedSortingTip() {
        guard Settings.shouldShowRecentlyPlayedSortingTip,
            let recentlyPlayedSortingTip
        else {
            return
        }
        Analytics.track(.episodeRecentlyPlayedSortOptionTooltipDismissed)
        Settings.shouldShowRecentlyPlayedSortingTip = false
        recentlyPlayedSortingTip.dismiss(animated: true) { [weak self] in
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
