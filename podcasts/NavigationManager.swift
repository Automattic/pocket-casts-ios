import PocketCastsDataModel
import PocketCastsServer
import UIKit
import PocketCastsUtils

class NavigationManager {
    static let podcastPageKey = "podcastPage"
    static let podcastKey = "podcast"

    static let folderPageKey = "folderPage"
    static let folderKey = "folder"
    static let popToRootViewController = "popToRootViewController"

    static let episodePageKey = "episodePage"
    static let episodeUuidKey = "episode"
    static let episodeTimestamp = "episodeTimestamp"

    private static let homePageKey = "homePage"
    static let podcastListPageKey = "podcastList"
    static let discoverPageKey = "discoverPage"
    static let discoverCategoryKey = "discoverCategory"
    static let discoverListKey = "discoverList"

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

    static let settingsPageKey = "settingsPage"
    static let settingsRowKey = "settingsRow"
    static let settingsAppearanceKey = "appearancePage"
    static let settingsAppearanceShowThemeKey = "appearanceShowThemeKey"
    static let settingsProfileKey = "profilePage"
    static let profileRowKey = "profileRow"
    static let profileRowDownloadsKey = "downloads"
    static let settingsHeadphoneKey = "headphoneSettings"
    static let settingsRedeemGuestPassKey = "redeemGuestPassPage"
    static let redeemGuestPassURLKey = "redeemGuestPassURLKey"

    static let endOfYearStories = "endOfYearStories"
    static let onboardingFlow = "onboardingFlow"

    static let settingsGeneralKey = "generalSettingsPage"
    static let settingsGeneralRowKey = "generalSettingsRow"

    static let upNextPageKey = "upNextPage"
    static let signUpPageKey = "signUpPage"
    static let importPageKey = "importPage"

    static let featurePageKey = "featurePageKey"
    static let featureKey = "featureKey"

    static let manualPlaylistsChooserKey = "manualPlaylistsChooserKey"
    static let manualPlaylistsChooserEpisodeKey = "manualPlaylistsChooserEpisodeKey"
    static let manualPlaylistsChooserRootKey = "manualPlaylistsChooserRootKey"

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

    func navigateTo(_ place: String, data: NSDictionary? = nil, animated: Bool = true) {
        performNavigation(place, data: data, animated: animated)
    }

    func mainViewControllerDidLoad(controller: NavigationProtocol) {
        mainController = controller
    }

    func dismissPresentedViewController(completion: (() -> Void)? = nil) {
        mainController?.dismissPresentedViewController(completion: completion)
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

            mainController?.navigateToEpisode(uuid, podcastUuid: data[NavigationManager.podcastKey] as? String, timestamp: data[NavigationManager.episodeTimestamp] as? TimeInterval)
        } else if place == NavigationManager.podcastListPageKey {
            mainController?.navigateToPodcastList(animated)
        } else if place == NavigationManager.discoverPageKey {
            navigateToDiscover(data: data, animated: animated)
        } else if place == NavigationManager.filterPageKey {
            if let data = data, let filterUuid = data[NavigationManager.filterUuidKey] as? String, let filter = DataManager.sharedManager.findPlaylist(uuid: filterUuid) {
                mainController?.navigateToFilter(filter, animated: animated)
            } else {
                mainController?.navigateToFilter(nil, animated: animated)
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
                let flow = data["flow"] as? OnboardingFlow.Flow
                mainController?.showSubscriptionRequired(rootVC, source: source, context: context, flow: flow ?? .plusUpsell)
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
            var showThemeSelection = false
            if let data = data, let showThemeSelectionValue = data[NavigationManager.settingsAppearanceShowThemeKey] as? Bool {
                showThemeSelection = showThemeSelectionValue
            }
            mainController?.showSettingsAppearance(showThemeSelection: showThemeSelection)
        } else if place == NavigationManager.settingsProfileKey {
            navigateToProfile(data: data, animated: animated)
        }
        else if place == NavigationManager.settingsHeadphoneKey {
            mainController?.showHeadphoneSettings()
        }
        else if place == NavigationManager.settingsRedeemGuestPassKey {
            guard let data = data, let url = data[NavigationManager.redeemGuestPassURLKey] as? URL else {
                return
            }
            mainController?.showRedeemGuestPass(url: url)
        }
        else if place == NavigationManager.showPromotionPageKey {
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
        } else if place == NavigationManager.settingsGeneralKey {
            mainController?.showGeneralSettings(row: data?[NavigationManager.settingsGeneralRowKey] as? GeneralSettingsViewController.TableRow)
        } else if place == NavigationManager.upNextPageKey {
            mainController?.navigateToUpNext(true)
        } else if place == NavigationManager.signUpPageKey {
            mainController?.showSignUp()
        } else if place == NavigationManager.settingsPageKey {
            let row = data?[NavigationManager.settingsRowKey] as? SettingsViewController.TableRow
            mainController?.showSettings(row: row)
        } else if place == NavigationManager.featurePageKey {
            navigateToFeature(data: data, animated: animated)
        } else if place == NavigationManager.manualPlaylistsChooserKey {
            if let episode = data?[NavigationManager.manualPlaylistsChooserEpisodeKey] as? Episode {
                let root = data?[NavigationManager.manualPlaylistsChooserRootKey] as? UIViewController
                mainController?.presentManualPlaylistsChooser(for: episode, rootViewController: root)
            }
        }
    }

    func navigateToDiscover(data: NSDictionary?, animated: Bool) {
        guard let data = data else {
            mainController?.navigateToDiscover(animated)
            return
        }

        if let category = data[NavigationManager.discoverCategoryKey] as? String {
            mainController?.navigateToDiscover(category: category, animated: animated)
            return
        }

        if let listId = data[NavigationManager.discoverListKey] as? String {
            mainController?.navigateToDiscover(listID: listId, animated: animated)
            return
        }
    }

    func navigateToFeature(data: NSDictionary?, animated: Bool) {
        guard let feature = data?[NavigationManager.featureKey] as? String else {
            return
        }
        if feature == "suggestedFolders" {
            mainController?.navigateToSuggestedFolders()
        }
    }

    func navigateToProfile(data: NSDictionary?, animated: Bool) {
        guard let row = data?[NavigationManager.profileRowKey] as? String else {
            return
        }
        if row == NavigationManager.profileRowDownloadsKey {
            mainController?.navigateToProfile(row: .downloaded, animated: animated)
        }
    }

    func showNotificationsPermissionsModal() {
        mainController?.showNotificationsPermissions()
    }
}

// MARK: - Helpers

extension NavigationManager {
    func showUpsellView(from controller: UIViewController, source: PlusUpgradeViewSource, context: OnboardingFlow.Context? = nil, flow: OnboardingFlow.Flow = .plusUpsell) {
        navigateTo(Self.subscriptionRequiredPageKey, data: [Self.subscriptionUpgradeVCKey: controller, "source": source, "flow": flow, "context": context ?? [:]])
    }
}
