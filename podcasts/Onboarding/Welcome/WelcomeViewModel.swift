import Foundation
import SwiftUI
import PocketCastsServer

class WelcomeViewModel: ObservableObject {
    var navigationController: UINavigationController?
    let displayType: DisplayType
    let sections: [WelcomeSection] = [.importPodcasts, .discover]

    var newsletterOptIn: Bool = true

    init(navigationController: UINavigationController? = nil, displayType: DisplayType) {
        self.navigationController = navigationController
        self.displayType = displayType
    }

    func sectionTapped(_ section: WelcomeSection) {
        saveNewsletterOptIn()

        switch section {
        case .importPodcasts:
            let viewModel = ImportViewModel()
            let controller = OnboardingHostingViewController(rootView: ImportLandingView(viewModel: viewModel).setupDefaultEnvironment())
            viewModel.navigationController = navigationController
            navigationController?.pushViewController(controller, animated: true)

        case .discover:
            navigationController?.dismiss(animated: true)
            NavigationManager.sharedManager.navigateTo(NavigationManager.discoverPageKey, data: nil)
        }
    }

    func doneTapped() {
        saveNewsletterOptIn()
        navigationController?.dismiss(animated: true)
    }

    private func saveNewsletterOptIn() {
        Analytics.track(.newsletterOptInChanged, properties: ["enabled": newsletterOptIn, "source": "account_updated"])
        ServerSettings.setMarketingOptIn(newsletterOptIn)
    }

    // MARK: - Configuration
    enum DisplayType {
        case plus
        case newAccount
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
        viewModel.navigationController = navigationController
        let controller = OnboardingHostingViewController(rootView: WelcomeView(viewModel: viewModel).setupDefaultEnvironment())
        controller.navBarIsHidden = true

        // Create our own nav controller if we're not already going in one
        let navController = navigationController ?? OnboardingNavigationViewController(rootViewController: controller)
        viewModel.navigationController = navController

        return (navigationController == nil) ? navController : controller
    }
}
