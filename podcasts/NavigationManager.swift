import PocketCastsDataModel
import PocketCastsServer
import UIKit

class NavigationManager {
    static let podcastPageKey = "podcastPage"
    static let podcastKey = "podcast"

    static let folderPageKey = "folderPage"
    static let folderKey = "folder"
    static let popToRootViewController = "popToRootViewController"

    static let episodePageKey = "episodePage"
    static let episodeUuidKey = "episode"

    private static let homePageKey = "homePage"
    static let podcastListPageKey = "podcastList"
    static let discoverPageKey = "discoverPage"

    static let filterPageKey = "filterPage"
    static let filterUuidKey = "filterUuid"

    static let filterAddKey = "filterPageAdd"

    static let uploadedPageKey = "uploadedPage"
    static let uploadFileKey = "uploadFile"

    static let filesPageKey = "filesPage"

    static let subscriptionCancelledAcknowledgePageKey = "subscrptionCancelledAcknowledgePage"

    static let subscriptionUpgradeVCKey = "subscrptionUpgradeVC"
    static let subscriptionRequiredPageKey = "subscrptionRequiredPage"

    static let showPlusMarketingPageKey = "showPlusMarketingPage"
    static let showPromotionPageKey = "showPromotionPage"
    static let promotionInfoKey = "promotionInfoKey"
    static let showPromotionFinishedPageKey = "showPromotionFinishedPage"

    static let supporterSignInKey = "supporterSignInKey"
    static let supporterPodcastInfo = "supporterPodcastInfo"
    static let supporterBundlePageKey = "suppoerterBundlePage"
    static let supporterBundleUuid = "supporterBundleUuid"

    static let showPrivacyPolicyPageKey = "showPrivacyPage"
    static let showTermsOfUsePageKey = "showTermsOfUsePage"

    static let showWhatsNewPageKey = "showWhatsNewPage"
    static let whatsNewInfoKey = "WhatsNewInfo"

    static let openUrlInSafariVCKey = "openSafariVCUrlPage"
    static let safariVCUrlKey = "safariVCUrlKey"

    static let settingsAppearanceKey = "appearancePage"
    static let settingsProfileKey = "profilePage"

    static let endOfYearStories = "endOfYearStories"
    static let onboardingFlow = "onboardingFlow"

    static let sharedManager = NavigationManager()

    private weak var mainController: NavigationProtocol?
    var dimmingView: UIView?
    var miniPlayer: MiniPlayerViewController?

    private var firstSetupCompleted = false
    var isPhone = false

    private var lastNavKey = ""
    private var lastNavData: NSDictionary?

    init() {
        isPhone = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone
    }

    // MARK: - Navigation

    func navigateTo(_ place: String, data: NSDictionary?) {
        performNavigation(place, data: data, animated: true)
    }

    func mainViewControllerDidLoad(controller: NavigationProtocol) {
        mainController = controller
    }

    func dismissPresentedViewController() {
        mainController?.dismissPresentedViewController()
    }

    private func performNavigation(_ place: String, data: NSDictionary?, animated: Bool) {
        lastNavKey = place
        lastNavData = data

        if place == NavigationManager.podcastPageKey {
            guard let data = data else { return }

            if let podcast = data[NavigationManager.podcastKey] as? Podcast {
                mainController?.navigateToPodcast(podcast)
            }
            if let podcastUuid = data[NavigationManager.podcastKey] as? String {
                if let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true) {
                    mainController?.navigateToPodcast(podcast)
                }
            } else if let podcastInfo = data[NavigationManager.podcastKey] as? PodcastInfo {
                mainController?.navigateToPodcastInfo(podcastInfo)
            } else if let podcastHeader = data[NavigationManager.podcastKey] as? PodcastHeader {
                // legacy PodcastHeader support
                var podcastInfo = PodcastInfo()
                podcastInfo.uuid = podcastHeader.uuid
                podcastInfo.title = podcastHeader.title
                podcastInfo.shortDescription = podcastHeader.headerDescription
                podcastInfo.author = podcastHeader.author
                podcastInfo.iTunesId = podcastHeader.itunesId?.intValue

                mainController?.navigateToPodcastInfo(podcastInfo)
            } else if let searchResult = data[NavigationManager.podcastKey] as? PodcastFolderSearchResult {
                mainController?.navigateTo(podcast: searchResult)
            }
        } else if place == NavigationManager.folderPageKey {
            guard let data = data else { return }

            if let folder = data[NavigationManager.folderKey] as? Folder {
                mainController?.navigateToFolder(folder, popToRootViewController: (data[NavigationManager.popToRootViewController] as? Bool) ?? true)
            }
        } else if place == NavigationManager.episodePageKey {
            guard let data = data, let uuid = data[NavigationManager.episodeUuidKey] as? String else { return }

            mainController?.navigateToEpisode(uuid, podcastUuid: data[NavigationManager.podcastKey] as? String)
        } else if place == NavigationManager.podcastListPageKey {
            mainController?.navigateToPodcastList(animated)
        } else if place == NavigationManager.discoverPageKey {
            mainController?.navigateToDiscover(animated)
        } else if place == NavigationManager.filterPageKey {
            if let data = data, let filterUuid = data[NavigationManager.filterUuidKey] as? String, let filter = DataManager.sharedManager.findFilter(uuid: filterUuid) {
                mainController?.navigateToFilter(filter, animated: animated)
            }
        } else if place == NavigationManager.filterAddKey {
            mainController?.navigateToAddFilter()
        } else if place == NavigationManager.uploadedPageKey {
            if let data = data, let fileURL = data[NavigationManager.uploadFileKey] as? URL {
                mainController?.navigateToAddCustom(fileURL)
            }
        } else if place == NavigationManager.filesPageKey {
            mainController?.navigateToFiles()
        } else if place == NavigationManager.subscriptionCancelledAcknowledgePageKey {
            mainController?.showSubscriptionCancelledAcknowledge()
        } else if place == NavigationManager.subscriptionRequiredPageKey {
            if let data = data, let rootVC = data[NavigationManager.subscriptionUpgradeVCKey] as? UIViewController {
                let source = (data["source"] as? PlusUpgradeViewSource) ?? .unknown
                let context = data["context"] as? OnboardingFlow.Context
                mainController?.showSubscriptionRequired(rootVC, source: source, context: context)
            }
        } else if place == NavigationManager.showPlusMarketingPageKey {
            mainController?.showPlusMarketingPage()
        } else if place == NavigationManager.showPrivacyPolicyPageKey {
            mainController?.showPrivacyPolicy()
        } else if place == NavigationManager.showTermsOfUsePageKey {
            mainController?.showTermsOfUse()
        } else if place == NavigationManager.showWhatsNewPageKey {
            if let data = data, let whatsNewInfo = data[NavigationManager.whatsNewInfoKey] as? WhatsNewInfo {
                mainController?.showWhatsNew(whatsNewInfo: whatsNewInfo)
            }
        } else if place == NavigationManager.settingsAppearanceKey {
            mainController?.showSettingsAppearance()
        } else if place == NavigationManager.settingsProfileKey {
            mainController?.showProfilePage()
        } else if place == NavigationManager.showPromotionPageKey {
            var promoCode: String?
            if let data = data, let promoString = data[NavigationManager.promotionInfoKey] as? String {
                promoCode = promoString
            }
            mainController?.showPromotionPage(promoCode: promoCode)
        } else if place == NavigationManager.showPromotionFinishedPageKey {
            mainController?.showPromotionFinishedAcknowledge()
        } else if place == NavigationManager.supporterSignInKey {
            if let data = data {
                if let podcastInfo = data[NavigationManager.supporterPodcastInfo] as? PodcastInfo {
                    mainController?.showSupporterSignIn(podcastInfo: podcastInfo)
                } else if let bundleUuid = data[NavigationManager.supporterBundleUuid] as? String {
                    mainController?.showSupporterSignIn(bundleUuid: bundleUuid)
                }
            }
        } else if place == NavigationManager.supporterBundlePageKey {
            var bundleUuid: String?
            if let data = data, let uuid = data[NavigationManager.supporterBundleUuid] as? String {
                bundleUuid = uuid
            }
            mainController?.showSupporterBundleDetails(bundleUuid: bundleUuid)
        } else if place == NavigationManager.openUrlInSafariVCKey {
            if let data = data, let urlString = data[NavigationManager.safariVCUrlKey] as? String {
                mainController?.showInSafariViewController(urlString: urlString)
            }
        } else if place == NavigationManager.endOfYearStories {
            mainController?.showEndOfYearStories()
        } else if place == NavigationManager.onboardingFlow {
            let flow: OnboardingFlow.Flow? = data?["flow"] as? OnboardingFlow.Flow
            mainController?.showOnboardingFlow(flow: flow)
        }
    }
}

// MARK: - Helpers

extension NavigationManager {
    func showUpsellView(from controller: UIViewController, source: PlusUpgradeViewSource, context: OnboardingFlow.Context? = nil) {
        navigateTo(Self.subscriptionRequiredPageKey, data: [Self.subscriptionUpgradeVCKey: controller, "source": source, "context": context ?? [:]])
    }
}
