import SwiftUI
import PocketCastsServer

extension DeveloperMenuSection {
    static var screens: DeveloperMenuSection {
        DeveloperMenuSection(title: "Screens", items: [
            .menu("Present Screen", sections: [
                DeveloperMenuSection(title: "Onboarding", items: [
                    .sheet("Intro Carousel") { _ in
                        IntroCarouselView(coordinator: LoginCoordinator())
                    },
                    .sheet("Onboarding Recommendations") { _ in
                        NavigationStack {
                            OnboardingRecommendationsView(coordinator: LoginCoordinator())
                        }
                    },
                    .sheet("Onboarding Interests") { dismiss in
                        OnboardingInterestsPreview(dismiss: dismiss)
                    },
                    .sheet("Playlists Onboarding") { dismiss in
                        PlaylistsOnboardingView(onClose: dismiss)
                    }
                ]),
                DeveloperMenuSection(items: [
                    .sheet("Notifications Permissions") { _ in
                        NotificationsPermissionsView()
                    },
                    .sheet("Cancel Subscription Survey") { _ in
                        CancelSubscriptionSurveyView(viewModel: CancelSubscriptionSurveyViewModel(navigationController: nil))
                    },
                    .sheet("TV Device Approval") { _ in
                        DeviceApproveView(userCode: "", model: DeviceApproveViewModel(presentingViewController: SceneHelper.rootViewController(includeTopMost: true) ?? UIViewController()))
                    }
                ])
            ]),
            .link("Survey Debug Info") {
                SurveyDebugInfoView()
            }
        ])
    }
}

private struct OnboardingInterestsPreview: View {
    let dismiss: () -> Void

    @StateObject private var recommendationsViewModel = RecommendationsViewModel(configuration: .all)
    @State private var isShowingRecommendations = false

    var body: some View {
        if isShowingRecommendations {
            OnboardingRecommendationsView(coordinator: LoginCoordinator(), viewModel: recommendationsViewModel)
        } else {
            InterestsView(continueCallback: { categories in
                recommendationsViewModel.configuration = .preselected(categories)
                isShowingRecommendations = true
            }, notNowCallback: dismiss, isInsideNavigation: false)
        }
    }
}
