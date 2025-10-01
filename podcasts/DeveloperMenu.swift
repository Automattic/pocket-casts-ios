import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

struct DeveloperMenu: View {
    @State var showingImporter = false
    @State var showingExporter = false
    @State var showingPlaylistsOnboarding = false
    @State var showingRecommendationsOnboarding = false
    @State var showingInterestsOnboarding = false
    @State var showingRecommendationsOnboardingSelected = false
    @State var showSurvey = false
    @State var showIntroCarousel = false
    @State var showingNotificationsPermissions = false
    @State var enableDebugPlaylistLimit = false

    @StateObject var recommendationsViewModel = RecommendationsViewModel(configuration: .all)

    var body: some View {
        List {
            if #available(iOS 17.0, *) {
                Section {
                    Button(action: {
                        showingImporter.toggle()
                    }, label: {
                        Text("Import Bundle")
                    })
                    .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.pcasts]) { result in
                        switch result {
                        case .success(let url):
                            print("Selected: \(url)")
                            Task {
                                let fileWrapper = try FileWrapper(url: url)
                                try PCBundleDoc.performImport(from: fileWrapper)
                            }
                        case .failure(let error):
                            print("Failed to import pcasts: \(error)")
                        }
                    }
                    Button(action: {
                        showingExporter.toggle()
                    }, label: {
                        Text("Export Bundle")
                    })
                    .fileExporter(isPresented: $showingExporter, document: PCBundleDoc()) { result in
                        switch result {
                        case .success(let url):
                            print("Saved to: \(url)")
                        case .failure(let error):
                            print("Failed to export pcasts: \(error)")
                        }
                    }
                    Button(action: {
                        PCBundleDoc.delete()
                    }, label: {
                        Text("Reset Database + Settings")
                    })
                }
            }
            Section {
                Button(action: {
                    UIPasteboard.general.string = ServerSettings.pushToken()
                }, label: {
                    Text("Copy Push Token")
                })

                Button(action: {
                    UIPasteboard.general.string = ServerConfig.shared.syncDelegate?.uniqueAppId()
                }, label: {
                    Text("Copy Device ID")
                })
            }

            Section {
                Button("Corrupt Sync Login Token") {
                    ServerSettings.syncingV2Token = "badToken"
                }

                Button("Force Reload Discover") {
                    DiscoverServerHandler.shared.discoveryCache.removeAllCachedResponses()
                    URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
                    NotificationCenter.postOnMainThread(notification: Constants.Notifications.chartRegionChanged)
                }

                Button("Unsubscribe from all Podcasts") {
                    let podcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)

                    for podcast in podcasts {
                        PodcastManager.shared.unsubscribe(podcast: podcast)
                    }
                }

                Button("Clear all folder information") {
                    DataManager.sharedManager.clearAllFolderInformation()
                }

                Button("Force Reload Feature Flags") {
                    FirebaseManager.refreshRemoteConfig(expirationDuration: 0) { _ in
                        DispatchQueue.main.async {
                            (UIApplication.shared.delegate as? AppDelegate)?.updateRemoteFeatureFlags(forceReload: true)
                        }
                    }
                }
            }

            Section {
                Button("Set to No Plus") {
                    ServerSettings.setIapUnverifiedPurchaseReceiptDate(nil)
                    SubscriptionHelper.setSubscriptionPaid(Int(0))
                    SubscriptionHelper.setSubscriptionPlatform(Int(0))
                    SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 30.days).timeIntervalSince1970)
                    SubscriptionHelper.setSubscriptionAutoRenewing(false)
                    SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                    SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                    SubscriptionHelper.setSubscriptionType(SubscriptionType.none.rawValue)
                    SubscriptionHelper.subscriptionTier = .none
                    NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                    HapticsHelper.triggerSubscribedHaptic()
                }

                Button("Set to Paid Plus") {
                    SubscriptionHelper.setSubscriptionPaid(Int(1))
                    SubscriptionHelper.setSubscriptionPlatform(Int(1))
                    SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 30.days).timeIntervalSince1970)
                    SubscriptionHelper.setSubscriptionAutoRenewing(true)
                    SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                    SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.monthly.rawValue)
                    SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                    SubscriptionHelper.subscriptionTier = .plus

                    NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                    HapticsHelper.triggerSubscribedHaptic()
                }

                Button("Set to Paid Patron") {
                    SubscriptionHelper.setSubscriptionPaid(Int(1))
                    SubscriptionHelper.setSubscriptionPlatform(Int(1))
                    SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 30.days).timeIntervalSince1970)
                    SubscriptionHelper.setSubscriptionAutoRenewing(true)
                    SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                    SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.monthly.rawValue)
                    SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                    SubscriptionHelper.subscriptionTier = .patron

                    NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                    HapticsHelper.triggerSubscribedHaptic()
                }

                Group {
                    Button("Set to 150 Gift Days") {
                        SubscriptionHelper.setSubscriptionPaid(1)
                        SubscriptionHelper.setSubscriptionPlatform(SubscriptionPlatform.gift.rawValue)
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 150 * 1.days).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(150)
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .plus

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }

                    Button("Set to 150 Gift Days and Expiring in 1 day") {
                        SubscriptionHelper.setSubscriptionPaid(1)
                        SubscriptionHelper.setSubscriptionPlatform(SubscriptionPlatform.gift.rawValue)
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 1.days).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(150)
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .plus

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }

                    Button("Set to 150 Gift Days and Expiring in 29 days") {
                        SubscriptionHelper.setSubscriptionPaid(1)
                        SubscriptionHelper.setSubscriptionPlatform(SubscriptionPlatform.gift.rawValue)
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 30.days).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(150)
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .plus

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }

                    Button("Set to Lifetime") {
                        SubscriptionHelper.setSubscriptionPaid(Int(1))
                        SubscriptionHelper.setSubscriptionPlatform(Int(4))
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 11 * 365.days).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(Int(11 * 365.days))
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .plus

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Button("Set to Active but Cancelled: Plus") {
                        SubscriptionHelper.setSubscriptionPaid(Int(1))
                        SubscriptionHelper.setSubscriptionPlatform(Int(1))
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 3.days).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .plus

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }
                    Text("Expiring in 2 days")
                        .font(Font.footnote)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Button("Set to Active but Cancelled: Patron") {
                        SubscriptionHelper.setSubscriptionPaid(Int(1))
                        SubscriptionHelper.setSubscriptionPlatform(Int(1))
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 3.days).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .patron

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }
                    Text("Expiring in 2 days")
                        .font(Font.footnote)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Button("Set to Cancelled and Expired: Plus") {
                        SubscriptionHelper.setSubscriptionPaid(Int(0))
                        SubscriptionHelper.setSubscriptionPlatform(Int(1))
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: (1.days * -1)).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .plus

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }
                    Text("Cancelled subscription, but has passed expiration date")
                        .font(Font.footnote)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Button("Set to Cancelled and Expired: Patron") {
                        SubscriptionHelper.setSubscriptionPaid(Int(0))
                        SubscriptionHelper.setSubscriptionPlatform(Int(1))
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: (1.days * -1)).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .patron

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }
                    Text("Cancelled subscription, but has passed expiration date")
                        .font(Font.footnote)
                }

            } header: {
                VStack {
                    Text("Subscription Testing")
                    Text("⚠️ Temporary items only, the changes will only be active until the next server sync.")
                }
            }

            Section {
                EndOfYearDeveloperMenuButton()
            } header: {
                Text("End of Year")
            }

            Section {
                Button("Reset Informational Modal Visibility") {
                    Settings.shouldShowInitialOnboardingFlow = true
                    Settings.hasShownInformationalViewModal = false
                }
                Button("Reset banners visibility") {
                    InformationalBannerType.allCases.forEach {
                        UserDefaults.standard.set(false, forKey: "kInformational\($0.rawValue.capitalized)Banner")
                    }
                }
            } header: {
                Text("Encourage Account Creation Banners")
            }

            Section {
                Button("Reset CTA conditions") {
                    Settings.suggestedFoldersUpsellCount = 0
                    Settings.suggestedFoldersLastUpsellDate = nil
                }
            } header: {
                Text("Suggested Folders")
            }

            Section {
                Button("Notifications Permissions Screen") {
                    showingNotificationsPermissions.toggle()
                }.sheet(isPresented: $showingNotificationsPermissions) {
                    NotificationsPermissionsView()
                }
                Button("Speed Up Notifications") {
                    NotificationsGroup.speedUpNotifications = true
                }
                Button("Log Schedule") {
                    NotificationsCoordinator.shared.debugMode = true
                }
            } header: {
                Text("Notifications")
            }

            Section {
                Button("Present Cancel Subscription Survey") {
                    showSurvey = true
                }
                .sheet(isPresented: $showSurvey) {
                    CancelSubscriptionSurveyView(viewModel: CancelSubscriptionSurveyViewModel(navigationController: nil))
                }
                Button("Reset Cancel Subscription Survey visibility") {
                    Settings.subscriptionCancelledSurveyShown = false
                }
            } header: {
                Text("Cancel Subscription Survey")
            }

            Section {
                NavigationLink("Debug Info") {
                    SurveyDebugInfoView()
                        .navigationTitle("Survey Debug Info")
                        .navigationBarTitleDisplayMode(.inline)
                }
            } header: {
                Text("Ratings")
            }

            Section {
                Button("Show Playlists Onboarding") {
                    showingPlaylistsOnboarding = true
                }
                .sheet(isPresented: $showingPlaylistsOnboarding) {
                    PlaylistsOnboardingView(onClose: {
                        showingPlaylistsOnboarding = false
                    })
                }

                Button("Show Intro Carousel") {
                    showIntroCarousel = true
                }
                .sheet(isPresented: $showIntroCarousel) {
                    IntroCarouselView(coordinator: LoginCoordinator())
                }
            } header: {
                Text("Onboarding")
            }

            Section {
                Button("Show Onboarding Recommendations") {
                    showingRecommendationsOnboarding = true
                }
                .sheet(isPresented: $showingRecommendationsOnboarding) {
                    NavigationStack {
                        OnboardingRecommendationsView(coordinator: LoginCoordinator())
                            .environmentObject(Theme.sharedTheme)
                    }
                }
                Button("Show Onboarding Interests") {
                    showingInterestsOnboarding = true
                }
                .sheet(isPresented: $showingInterestsOnboarding) {
                    InterestsView(continueCallback: { categories in
                        showInterestRecommendations(categories: categories)
                    }, notNowCallback: {
                        showingInterestsOnboarding.toggle()
                    }, isInsideNavigation: false)
                        .environmentObject(Theme.sharedTheme)
                }
                .sheet(isPresented: $showingRecommendationsOnboardingSelected) {
                    OnboardingRecommendationsView(coordinator: LoginCoordinator(), viewModel: self.recommendationsViewModel)
                        .environmentObject(Theme.sharedTheme)
                }
            } header: {
                Text("Onboarding")
            }

            Section {
                Toggle(isOn: $enableDebugPlaylistLimit) {
                    Text("Enable Debug Playlists limit")
                }
                .onChange(of: enableDebugPlaylistLimit) { newValue in
                    Settings.debugPlaylistsLimit = newValue ? 6 : Constants.Limits.maxFilterItems
                }
            } header: {
                Text("Playlist Rebranding")
            }

            Section {
                Text(Bundle.main.identifier)
            } header: {
                Text("Bundle ID")
            }
        }
        .miniPlayerSafeAreaInset()
    }

    func showInterestRecommendations(categories: [DiscoverCategory]) {
        showingInterestsOnboarding = false
        recommendationsViewModel.configuration = .preselected(categories)
        showingRecommendationsOnboardingSelected = true
    }
}

struct DeveloperMenu_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperMenu()
    }
}

extension Bundle {

    var identifier: String {
        guard let infoDictionary = infoDictionary, let identifier = infoDictionary["CFBundleIdentifier"] as? String else {
            return "Cound not load bundle id."
        }

        return identifier

    }
}
