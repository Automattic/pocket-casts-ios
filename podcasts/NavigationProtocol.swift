import Foundation
import PocketCastsDataModel
import PocketCastsServer
import UIKit

protocol NavigationProtocol: AnyObject {
    func navigateToPodcastList(_ animated: Bool)
    func navigateToPodcast(_ podcast: Podcast)
    func navigateToPodcastInfo(_ podcastInfo: PodcastInfo)
    func navigateTo(podcast searchResult: PodcastFolderSearchResult)

    func navigateToFolder(_ folder: Folder, popToRootViewController: Bool)

    func navigateToEpisode(_ episodeUuid: String, podcastUuid: String?)

    func navigateToDiscover(_ animated: Bool)

    func navigateToProfile(_ animated: Bool)

    func navigateToFilter(_ filter: EpisodeFilter, animated: Bool)
    func navigateToEditFilter(_ filter: EpisodeFilter)
    func navigateToAddFilter()

    func navigateToFiles()
    func navigateToAddCustom(_ fileURL: URL)

    func showSubscriptionCancelledAcknowledge()
    func showSubscriptionRequired(_ upgradeRootViewController: UIViewController, source: PlusUpgradeViewSource, context: OnboardingFlow.Context?)
    func showPlusMarketingPage()
    func showSettingsAppearance()
    func showPromotionPage(promoCode: String?)
    func showPromotionFinishedAcknowledge()
    func showProfilePage()
    func showHeadphoneSettings()

    func showSupporterSignIn(podcastInfo: PodcastInfo)
    func showSupporterSignIn(bundleUuid: String)
    func showSupporterBundleDetails(bundleUuid: String?)
    func showTermsOfUse()
    func showPrivacyPolicy()

    func showWhatsNew(whatsNewInfo: WhatsNewInfo)

    func showInSafariViewController(urlString: String)

    func showEndOfYearStories()
    func dismissPresentedViewController()
    func showOnboardingFlow(flow: OnboardingFlow.Flow?)
}
