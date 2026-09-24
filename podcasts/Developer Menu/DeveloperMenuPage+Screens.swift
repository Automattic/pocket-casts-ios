import SwiftUI
import PocketCastsServer

extension DeveloperMenuPage {
    static var screens: DeveloperMenuPage {
        DeveloperMenuPage(title: "Screens", systemImage: "rectangle.stack", sections: [
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
            DeveloperMenuSection(title: "Other", items: [
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
