import Foundation
import PocketCastsServer
import SwiftUI

class PlusLandingViewModel: PlusPurchaseModel {
    weak var navigationController: UINavigationController? = nil

    var continuePurchasing: Constants.ProductInfo? = nil
    let source: Source

    init(source: Source, continuePurchasing: Constants.ProductInfo? = nil, purchaseHandler: IapHelper = .shared) {
        self.continuePurchasing = continuePurchasing
        self.source = source

        super.init(purchaseHandler: purchaseHandler)
    }

    func unlockTapped(plan: Constants.Plan = .plus, selectedPrice: PlusPricingInfoModel.DisplayPrice) {
        OnboardingFlow.shared.track(.plusPromotionUpgradeButtonTapped)

        guard SyncManager.isUserLoggedIn() else {
            let controller = LoginCoordinator.make(in: navigationController, fromUpgrade: true)
            navigationController?.pushViewController(controller, animated: true)
            return
        }

        loadPricesAndContinue(plan: plan, selectedPrice: selectedPrice)
    }

    func unlockTapped(ifLoggedIn: () -> Void) {
        OnboardingFlow.shared.track(.plusPromotionUpgradeButtonTapped)

        guard SyncManager.isUserLoggedIn() else {
            let controller = LoginCoordinator.make(in: navigationController, fromUpgrade: true)
            navigationController?.pushViewController(controller, animated: true)
            return
        }

        ifLoggedIn()
    }

    func didAppear() {
    override func didAppear() {
        OnboardingFlow.shared.track(.plusPromotionShown)

        guard continueUpgrade else { return }

        // Don't continually show when the user dismisses
        continueUpgrade = false

        if !FeatureFlag.patron.enabled {
            loadPricesAndContinue(plan: .plus, selectedPrice: .yearly)
        }
    }

    override func didDismiss(type: OnboardingDismissType) {
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

    func purchaseTitle(for tier: UpgradeTier, frequency: PlusPricingInfoModel.DisplayPrice) -> String {
        guard let product = pricingInfo.products.first(where: { $0.identifier == (frequency == .yearly ? tier.plan.yearly : tier.plan.monthly) }) else {
            return L10n.loading
        }

        if product.freeTrialDuration != nil {
            return L10n.plusStartMyFreeTrial
        } else {
            return tier.buttonLabel
        }
    }

    func purchaseSubtitle(for tier: UpgradeTier, frequency: PlusPricingInfoModel.DisplayPrice) -> String {
        guard let product = pricingInfo.products.first(where: { $0.identifier == (frequency == .yearly ? tier.plan.yearly : tier.plan.monthly) }) else {
            return ""
        }

        if let freeTrialDuration = product.freeTrialDuration {
            return L10n.plusStartTrialDurationPrice(freeTrialDuration, product.price)
        } else {
            return product.price
        }
    }

    private func loadPricesAndContinue(plan: Constants.Plan, selectedPrice: PlusPricingInfoModel.DisplayPrice) {
        loadPrices {
            switch self.priceAvailability {
            case .available:
                self.showModal(plan: plan, selectedPrice: selectedPrice)
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
    func showModal(plan: Constants.Plan, selectedPrice: PlusPricingInfoModel.DisplayPrice) {
        guard let navigationController else { return }

        let controller = PlusPurchaseModel.make(in: navigationController, plan: plan, selectedPrice: selectedPrice)
        controller.presentModally(in: navigationController)
    }

    func showError() {
        SJUIUtils.showAlert(title: L10n.plusUpgradeNoInternetTitle, message: L10n.plusUpgradeNoInternetMessage, from: navigationController)
    }
}

extension PlusLandingViewModel {
    static func make(in navigationController: UINavigationController? = nil, from source: Source, continueUpgrade: Bool = false) -> UIViewController {
        let viewModel = PlusLandingViewModel(source: source, continueUpgrade: continueUpgrade)
        let purchaseModel = FeatureFlag.patron.enabled ? PlusPurchaseModel() : nil

        let view = Self.view(with: viewModel, purchaseModel: purchaseModel)
        let controller = PlusHostingViewController(rootView: view)

        controller.viewModel = viewModel
        controller.navBarIsHidden = true

        // Create our own nav controller if we're not already going in one
        let navController = navigationController ?? UINavigationController(rootViewController: controller)
        viewModel.navigationController = navController
        purchaseModel?.parentController = navController

        return (navigationController == nil) ? navController : controller
    }

    @ViewBuilder
    private static func view(with viewModel: PlusLandingViewModel, purchaseModel: PlusPurchaseModel? = nil) -> some View {
        if FeatureFlag.patron.enabled, let purchaseModel {
            UpgradeLandingView()
                .environmentObject(viewModel)
                .environmentObject(purchaseModel)
                .setupDefaultEnvironment()
        } else {
            PlusLandingView(viewModel: viewModel)
                .setupDefaultEnvironment()
        }
    }
}
