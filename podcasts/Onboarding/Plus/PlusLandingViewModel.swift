import Foundation
import PocketCastsServer
import SwiftUI

class PlusLandingViewModel: PlusPurchaseModel {
    weak var navigationController: UINavigationController? = nil

    let displayedProducts: [UpgradeTier]
    var initialProduct: Constants.ProductInfo? = nil
    var continuePurchasing: Constants.ProductInfo? = nil
    let source: Source

    init(source: Source, config: Config? = nil, purchaseHandler: IapHelper = .shared) {
        self.displayedProducts = config?.products ?? [.plus, .patron]
        self.initialProduct = config?.displayProduct
        self.continuePurchasing = config?.continuePurchasing
        self.source = source

        super.init(purchaseHandler: purchaseHandler)

        self.loadPrices()
    }

    func unlockTapped(_ product: Constants.ProductInfo) {
        OnboardingFlow.shared.track(.plusPromotionUpgradeButtonTapped)

        guard SyncManager.isUserLoggedIn() else {
            let controller = LoginCoordinator.make(in: navigationController, continuePurchasing: product)
            navigationController?.pushViewController(controller, animated: true)
            return
        }

        loadPricesAndContinue(product: product)
    }

    override func didAppear() {
        OnboardingFlow.shared.track(.plusPromotionShown)

        guard let continuePurchasing else { return }

        // Don't continually show when the user dismisses
        self.continuePurchasing = nil

        loadPricesAndContinue(product: continuePurchasing)
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

    func purchaseTitle(for tier: UpgradeTier, frequency: Constants.PlanFrequency) -> String {
        guard let product = product(for: tier.plan, frequency: frequency) else {
            return L10n.loading
        }

        if let offer = product.offer {
            return offer.title
        } else {
            return tier.buttonLabel
        }
    }

    func purchaseSubtitle(for tier: UpgradeTier, frequency: Constants.PlanFrequency) -> String {
        guard let product = product(for: tier.plan, frequency: frequency) else {
            return ""
        }

        if let offer = product.offer {
            return offer.comparation
        } else {
            return product.price
        }
    }

    private func product(for plan: Constants.Plan, frequency: Constants.PlanFrequency) -> PlusProductPricingInfo? {
        pricingInfo.products.first(where: { $0.identifier == (frequency == .yearly ? plan.yearly : plan.monthly) })
    }

    private func loadPricesAndContinue(product: Constants.ProductInfo) {
        loadPrices {
            switch self.priceAvailability {
            case .available:
                self.showModal(product: product)
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

    struct Config {
        var products: [UpgradeTier]? = nil
        var displayProduct: Constants.ProductInfo? = nil
        var continuePurchasing: Constants.ProductInfo? = nil
    }
}

private extension PlusLandingViewModel {
    func showModal(product: Constants.ProductInfo) {
        guard let product = self.product(for: product.plan, frequency: product.frequency) else {
            state = .failed
            return
        }

        purchase(product: product.identifier)
        return
    }

    func showError() {
        SJUIUtils.showAlert(title: L10n.plusUpgradeNoInternetTitle, message: L10n.plusUpgradeNoInternetMessage, from: navigationController)
    }
}

extension PlusLandingViewModel {
    static func make(in navigationController: UINavigationController? = nil, from source: Source, config: PlusLandingViewModel.Config? = nil) -> UIViewController {
        let viewModel = PlusLandingViewModel(source: source, config: config)

        let view = Self.view(with: viewModel)
        let controller = PlusHostingViewController(rootView: view)

        controller.viewModel = viewModel
        controller.navBarIsHidden = true

        // Create our own nav controller if we're not already going in one
        let navController = navigationController ?? UINavigationController(rootViewController: controller)
        viewModel.navigationController = navController
        viewModel.parentController = navController

        return (navigationController == nil) ? navController : controller
    }

    @ViewBuilder
    private static func view(with viewModel: PlusLandingViewModel) -> some View {
        UpgradeLandingView(viewModel: viewModel)
            .setupDefaultEnvironment()
    }
}
