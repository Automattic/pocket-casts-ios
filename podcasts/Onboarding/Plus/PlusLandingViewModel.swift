import Foundation
import PocketCastsServer
import SwiftUI

class PlusLandingViewModel: PlusPricingInfoModel, OnboardingModel {
    weak var navigationController: UINavigationController? = nil

    var continueUpgrade: Bool
    let source: Source

    init(source: Source, continueUpgrade: Bool = false, purchaseHandler: IapHelper = .shared) {
        self.continueUpgrade = continueUpgrade
        self.source = source

        super.init(purchaseHandler: purchaseHandler)
    }

    func unlockTapped() {
        OnboardingFlow.shared.track(.plusPromotionUpgradeButtonTapped)

        guard SyncManager.isUserLoggedIn() else {
            let controller = LoginCoordinator.make(in: navigationController, fromUpgrade: true)
            navigationController?.pushViewController(controller, animated: true)
            return
        }

        loadPricesAndContinue()
    }

    func didAppear() {
        OnboardingFlow.shared.track(.plusPromotionShown)

        guard continueUpgrade else { return }

        // Don't continually show when the user dismisses
        continueUpgrade = false

        self.loadPricesAndContinue()
    }

    func didDismiss(type: OnboardingDismissType) {
        guard type == .swipe else { return }

        OnboardingFlow.shared.track(.plusPromotionDismissed)
    }

    func dismissTapped() {
        OnboardingFlow.shared.track(.plusPromotionDismissed)

        guard source == .accountCreated else {
            navigationController?.dismiss(animated: true)
            return
        }

        let controller = WelcomeViewModel.make(in: navigationController, displayType: .newAccount)
        navigationController?.pushViewController(controller, animated: true)
    }

    func price(for tier: UpgradeTier, frequency: UpgradeLandingView.DisplayPrice) -> String {
        pricingInfo.products.first(where: { $0.identifier.rawValue == (frequency == .yearly ? tier.yearlyIdentifier : tier.monthlyIdentifier) })?.rawPrice ?? "?"
    }

    private func loadPricesAndContinue() {
        loadPrices {
            switch self.priceAvailability {
            case .available:
                self.showModal()
            case .failed:
                self.showError()
            default:
                break
            }
        }
    }

    enum Source {
        case upsell
        case login
        case accountCreated
    }
}

private extension PlusLandingViewModel {
    func showModal() {
        guard let navigationController else { return }

        let controller = PlusPurchaseModel.make(in: navigationController)
        controller.presentModally(in: navigationController)
    }

    func showError() {
        SJUIUtils.showAlert(title: L10n.plusUpgradeNoInternetTitle, message: L10n.plusUpgradeNoInternetMessage, from: navigationController)
    }
}

extension PlusLandingViewModel {
    static func make(in navigationController: UINavigationController? = nil, from source: Source, continueUpgrade: Bool = false) -> UIViewController {
        let viewModel = PlusLandingViewModel(source: source, continueUpgrade: continueUpgrade)

        let view = Self.view(with: viewModel)
        let controller = PlusHostingViewController(rootView: view)

        controller.viewModel = viewModel
        controller.navBarIsHidden = true

        // Create our own nav controller if we're not already going in one
        let navController = navigationController ?? UINavigationController(rootViewController: controller)
        viewModel.navigationController = navController

        return (navigationController == nil) ? navController : controller
    }

    @ViewBuilder
    private static func view(with viewModel: PlusLandingViewModel) -> some View {
        if FeatureFlag.patron.enabled {
            UpgradeLandingView()
                .environmentObject(viewModel)
                .setupDefaultEnvironment()
        } else {
            PlusLandingView(viewModel: viewModel)
                .setupDefaultEnvironment()
        }
    }
}
