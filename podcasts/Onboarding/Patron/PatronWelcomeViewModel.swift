import SwiftUI

class PatronWelcomeViewModel: ObservableObject, OnboardingModel {
    weak var navigationController: UINavigationController?

    let icons: [IconType] = [
        .patronDark, .patronGlow,
        .patronRound, .patronChrome
    ]

    init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
    }

    func didAppear() {
        track(.welcomeShown)
    }

    func didDismiss(type: OnboardingDismissType) {
        guard type == .swipe else { return }

        track(.welcomeDismissed)
    }

    func iconSelected(_ icon: IconType) {
        let name = icon.iconName

        UIApplication.shared.setAlternateIconName(name) { _ in
            WidgetHelper.shared.updateWidgetAppIcon()
        }

        OnboardingFlow.shared.track(.patronWelcomeAppIconChanged, properties: ["icon": name ?? "default"])
    }

    func continueTapped() {
        track(.welcomeDismissed)
        navigationController?.dismiss(animated: true)
    }
}

extension PatronWelcomeViewModel {
    static func make(in navigationController: UINavigationController? = nil) -> UIViewController {
        let viewModel = PatronWelcomeViewModel()
        let controller = OnboardingHostingViewController(rootView: PatronAppIconUnlock(viewModel: viewModel))

        controller.navBarIsHidden = true

        // Create our own nav controller if we're not already going in one
        let navController = navigationController ?? UINavigationController(rootViewController: controller)
        viewModel.navigationController = navController
        controller.viewModel = viewModel

        return (navigationController == nil) ? navController : controller
    }
}


private extension PatronWelcomeViewModel {
    func track(_ event: AnalyticsEvent) {
        OnboardingFlow.shared.track(event, properties: ["display_type": "patron"])
    }
}
