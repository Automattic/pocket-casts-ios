import SwiftUI

class CancelSubscriptionSurveyViewModel: ObservableObject, OnboardingModel {
    enum Reason: String, CaseIterable, Identifiable {
        case betterApp = "found_better_app"
        case technical = "technical_issue"
        case cost = "cost"
        case notEnoughUse = "not_used_enough"
        case other = "other"

        var id: String { rawValue }

        var description: String {
            switch self {
            case .betterApp:
                L10n.cancelSubscriptionSurveyRowBetterApp
            case .technical:
                L10n.cancelSubscriptionSurveyRowTechnicalIssue
            case .cost:
                L10n.cancelSubscriptionSurveyRowCost
            case .notEnoughUse:
                L10n.cancelSubscriptionSurveyRowNotEnough
            case .other:
                L10n.cancelSubscriptionSurveyRowOther
            }
        }
    }

    enum LoadingState {
        case idle
        case loading
    }

    @Published var selectedReason: Reason?
    @Published var additionalText: String = ""
    @Published var loadingState: LoadingState = .idle

    var isLoading: Bool {
        loadingState == .loading
    }

    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    var canSendFeedback: Bool {
        if let selectedReason {
            if selectedReason == .other {
                return !additionalText.isEmpty
            }
            return true
        }
        return false
    }

    func sendFeedback() {
        if loadingState == .loading {
            return
        }
        loadingState = .loading
        Analytics.track(.cancelSubscriptionSurveySubmitButtonTapped)
    }

    func dismiss() {
        Analytics.track(.cancelSubscriptionSurveyDismissed)
        navigationController?.dismiss(animated: true)
    }

    func didAppear() {
        Analytics.track(.cancelSubscriptionSurveyShown)
    }

    func didDismiss(type: OnboardingDismissType) {
        guard type == .swipe else { return }
        Analytics.track(.cancelSubscriptionSurveyDismissed)
    }
}

// Making vew controller
extension CancelSubscriptionSurveyViewModel {
    /// Make the view, and allow it to be shown by itself or within another navigation flow
    static func make() -> UINavigationController {
        // If we're not being presented within another nav controller then wrap ourselves in one
        let navController = UINavigationController()
        let viewModel = CancelSubscriptionSurveyViewModel(navigationController: navController)

        // Wrap the SwiftUI view in the hosting view controller
        let swiftUIView = CancelSubscriptionSurveyView(viewModel: viewModel).setupDefaultEnvironment()

        // Configure the controller
        let controller = OnboardingHostingViewController(rootView: swiftUIView)
        controller.navBarIsHidden = true
        controller.viewModel = viewModel

        // Set the root view of the new nav controller
        navController.setViewControllers([controller], animated: false)
        return navController
    }
}
