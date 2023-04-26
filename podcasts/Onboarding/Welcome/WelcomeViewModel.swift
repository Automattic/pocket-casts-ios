import Foundation
import SwiftUI
import PocketCastsServer

class WelcomeViewModel: ObservableObject, OnboardingModel {
    weak var navigationController: UINavigationController?
    let displayType: DisplayType
    let sections: [WelcomeSection] = [.importPodcasts, .discover]

    var newsletterOptIn: Bool = true

    init(navigationController: UINavigationController? = nil, displayType: DisplayType) {
        self.navigationController = navigationController
        self.displayType = displayType
    }

    func didAppear() {
        track(.welcomeShown)
    }

    func didDismiss(type: OnboardingDismissType) {
        guard type == .swipe else { return }

        saveNewsletterOptIn()
        track(.welcomeDismissed)
    }

    func sectionTapped(_ section: WelcomeSection) {
        saveNewsletterOptIn()

        switch section {
        case .importPodcasts:
            track(.welcomeImportTapped)
            let controller = ImportViewModel.make(in: navigationController)
            navigationController?.pushViewController(controller, animated: true)

        case .discover:
            track(.welcomeDiscoverTapped)
            navigationController?.dismiss(animated: true)
            NavigationManager.sharedManager.navigateTo(NavigationManager.discoverPageKey, data: nil)
        }
    }

    func doneTapped() {
        saveNewsletterOptIn()
        track(.welcomeDismissed)
        navigationController?.dismiss(animated: true)
    }

    private func saveNewsletterOptIn() {
        let source: String
        switch displayType {
        case .newAccount: source = "welcome_new_account"
        case .plus: source = "welcome_plus"
        }

        Analytics.track(.newsletterOptInChanged, properties: ["enabled": newsletterOptIn, "source": source])
        ServerSettings.setMarketingOptIn(newsletterOptIn)
    }

    // MARK: - Configuration
    enum DisplayType: String, AnalyticsDescribable {
        case plus
        case newAccount = "created_account"

        var analyticsDescription: String { rawValue }
    }

    enum WelcomeSection: Int, Identifiable {
        case importPodcasts
        case discover

        var id: Int { rawValue }
    }
}

extension WelcomeViewModel {
    static func make(in navigationController: UINavigationController? = nil, displayType: DisplayType) -> UIViewController {
        let viewModel = WelcomeViewModel(displayType: displayType)

        let controller = OnboardingHostingViewController(rootView: WelcomeView(viewModel: viewModel).setupDefaultEnvironment())
        controller.navBarIsHidden = true

        // Create our own nav controller if we're not already going in one
        let navController = navigationController ?? UINavigationController(rootViewController: controller)
        viewModel.navigationController = navController
        controller.viewModel = viewModel

        return (navigationController == nil) ? navController : controller
    }
}

private extension WelcomeViewModel {
    func track(_ event: AnalyticsEvent) {
        OnboardingFlow.shared.track(event, properties: ["display_type": displayType])
    }
}
