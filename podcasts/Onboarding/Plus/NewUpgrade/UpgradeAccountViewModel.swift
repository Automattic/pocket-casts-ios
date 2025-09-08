import Foundation
import SwiftUI

import PocketCastsServer
import PocketCastsUtils

class UpgradeAccountViewModel: PlusPurchaseModel {

    enum PresentationStyle {
        case generic
        case contextual
    }

    weak var navigationController: UINavigationController? = nil

    @Published var upgradeTier: UpgradeTier = .plus
    @Published var selectedProduct: IAPProductID = .yearly
    @Published var products: [PlusProductPricingInfo] = []

    @Published private(set) var selectedFrequency: PlanFrequency = .yearly

    let viewSource: PlusUpgradeViewSource

    let flowSource: PlusLandingViewModel.Source

    let style: PresentationStyle

    init(upgradeTier: UpgradeTier = .plus, selectedProduct: IAPProductID = .yearly, viewSource: PlusUpgradeViewSource = .unknown, flowSource: PlusLandingViewModel.Source, style: PresentationStyle = .generic) {
        self.upgradeTier = upgradeTier
        self.selectedProduct = selectedProduct
        self.viewSource = viewSource
        self.flowSource = flowSource
        self.style = style
        super.init()
        loadPrices() {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.products = self.pricingInfo.products.filter {
                    self.upgradeTier.plan.products.contains($0.identifier)
                }
            }
        }
    }

    var features: [UpgradeTier.TierFeature] {
        if selectedProduct.isYearlyProduct {
            return upgradeTier.yearlyFeatures
        } else {
            return upgradeTier.monthlyFeatures
        }
    }

    var shouldShowVariation: Bool {
        guard FeatureFlag.newOnboardingVariant.enabled, isFreeTrialAvailable, FeatureFlag.newOnboardingUpgradeTrialTimeline.enabled else {
            return false
        }
        return ABTestProvider.shared.variation(for: .pocketcastsNewOnboardingIOSABTest) == .treatment
    }

    var isFreeTrialAvailable: Bool {
        guard pricingInfo.hasOffer, let product = pricingInfo.products.first(where: {$0.identifier == selectedProduct}) else {
            return false
        }
        guard let offer = product.offer else {
            return false
        }

        return offer.type == .freeTrial
    }

    var timelineEvents: [TimelineEvent] {
        guard let product = pricingInfo.products.first(where: {$0.identifier == selectedProduct}),
              let offer = product.offer, offer.type == .freeTrial,
              let offerEndDate = offer.offerEndDate,
              let oneWeekBeforeDate = offerEndDate.sevenDaysAgo()
        else {
            return []
        }
        var events = [TimelineEvent]()


        let todayEvent = TimelineEvent(iconName: "unlocked-large", title: L10n.today, detail: L10n.upgradeAccountTimelineDay1)
        events.append(todayEvent)

        let oneWeekBeforeDateLocalized = oneWeekBeforeDate.formatted(date: .abbreviated, time: .omitted)
        let oneWeekBeforeEvent = TimelineEvent(iconName: "mail", title: oneWeekBeforeDateLocalized, detail: L10n.upgradeAccountTimelineWeekBefore)
        events.append(oneWeekBeforeEvent)

        let chargingEvent = TimelineEvent(iconName: "star_empty", title: offer.offerEndDateLocalized, detail: L10n.upgradeAccountTimelineChargingDay(offer.offerEndDateLocalized))

        events.append(chargingEvent)

        return events
    }

    func selectProduct(_ product: IAPProductID) {
        selectedProduct = product
        if selectedProduct.isYearlyProduct {
            selectedFrequency = .yearly
        } else {
            selectedFrequency = .monthly
        }
        changedSubscriptionPeriod(selectedFrequency)
    }

    var savingsOnBestValue: String? {
        guard let bestProduct = products.first(where: { $0.isBestValue }),
            let otherProduct = products.first(where: { $0.isBestValue == false }),
            bestProduct.basePrice != 0,
            otherProduct.basePrice != 0
        else {
            return nil
        }
        let savings = 1.0 - (bestProduct.basePrice / otherProduct.basePrice)

        let percentSavings = savings.localized(.percent)

        return L10n.subscriptionPlanSavings(percentSavings)
    }

    func dismissTapped(originalDismiss dismiss: DismissAction?) {
        track(.plusPromotionDismissed)

        guard flowSource == .accountCreated, !FeatureFlag.newOnboardingAccountCreation.enabled, let navigationController else {
            if navigationController == nil {
                dismiss?()
            } else {
                navigationController?.dismiss(animated: true)
            }
            return
        }

        let controller = WelcomeViewModel.make(in: navigationController, displayType: .newAccount)
        navigationController.pushViewController(controller, animated: true)
    }

    var title: String {
        return customTitle ?? upgradeTier.header
    }

    func purchaseTapped() {
        track(.plusPromotionUpgradeButtonTapped)

        guard SyncManager.isUserLoggedIn() else {
            presentLogin(with: ProductInfo.init(plan: upgradeTier.plan, frequency: selectedFrequency))
            return
        }
        purchase(product: selectedProduct)
    }

    func presentLogin(with product: ProductInfo? = nil) {
        let controller = LoginCoordinator.make(in: navigationController, continuePurchasing: product)
        navigationController?.pushViewController(controller, animated: true)
    }

    func changedSubscriptionPeriod(_ value: PlanFrequency) {
        track(.plusPromotionSubscriptionFrequencyChanged, properties: ["value": value.rawValue])
    }

    func termsOfUseTapped() {
        track(.plusPromotionTermsAndConditionsTapped)
    }

    func privacyPolicyTapped() {
        track(.plusPromotionPrivacyPolicyTapped)
    }

    // MARK: - Onboarding Model overrides
    override func didAppear() {
        track(.plusPromotionShown)
    }

    override func didDismiss(type: OnboardingDismissType) {
        guard type == .swipe else { return }

        track(.plusPromotionDismissed)
    }

    // MARK: - custom animation

    var customAnimation: some View {
        viewSource.customAnimation
    }

    func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        var baseProperties: [String: Any] = [:]

        baseProperties["version"] = "1"
        baseProperties["variant"] = style == .generic && shouldShowVariation ? "B" : "A"

        let mergedProperties = baseProperties.merging(properties ?? [:]) { current, _ in current }
        OnboardingFlow.shared.track(event, properties: mergedProperties)
    }
}

// MARK: - Factory methods
extension UpgradeAccountViewModel {

    static func make(in parentController: UIViewController? = nil,
                     flowSource: PlusLandingViewModel.Source,
                     viewSource: PlusUpgradeViewSource,
                     plan: Plan, frequency: PlanFrequency) -> UIViewController {

        let viewModel = UpgradeAccountViewModel(upgradeTier: plan.tier, selectedProduct: product(for: plan, frequency: frequency), viewSource: viewSource, flowSource: flowSource, style: viewSource.presentationStyle)

        let view = UpgradeAccountView(model: viewModel)
        let controller = OnboardingHostingViewController(rootView: view.setupDefaultEnvironment())
        controller.modalPresentationStyle = .fullScreen
        controller.navBarIsHidden = true
        controller.viewModel = viewModel

        viewModel.customTitle = viewSource.customTitle
        viewModel.parentController = parentController
        viewModel.navigationController = parentController as? UINavigationController

        if parentController == nil {
            // Create our own nav controller if we're not already going in one
            let navController = UINavigationController(rootViewController: controller)
            navController.modalPresentationStyle = .fullScreen
            viewModel.navigationController = navController
            viewModel.parentController = navController
            return navController
        } else {
            return controller
        }
    }

    private static func product(for plan: Plan, frequency: PlanFrequency) -> IAPProductID {
        switch plan {
            case .patron:
                switch frequency {
                    case .yearly:
                        return .patronYearly
                    case .monthly:
                        return .patronMonthly
                }
            case .plus:
                switch frequency {
                    case .monthly:
                        return .monthly
                    case .yearly:
                        return .yearly
                }
        }
    }
}

extension Plan {

    var tier: UpgradeTier {
        switch self {
            case .patron:
                return .patron
            case .plus:
                return .plus
        }
    }
}

private extension PlusUpgradeViewSource {

    var presentationStyle: UpgradeAccountViewModel.PresentationStyle {
        switch self {
            case .deselectChapters, .deselectChapterWhatsNew:
                return .contextual
            case .upNextShuffle:
                return .contextual
            case .bookmarksLocked, .bookmarksShelfAction:
                return .contextual
            case .folders, .suggestedFolders:
                return .contextual
            default:
                return .generic
        }
    }

    var customTitle: String? {
        switch self {
            case .deselectChapters, .deselectChapterWhatsNew:
                return L10n.subscriptionFeatureCustomTitlePreSelectedChapters
            case .upNextShuffle:
                return L10n.subscriptionFeatureCustomTitleShuffleUpnext
            case .bookmarksLocked, .bookmarksShelfAction:
                return L10n.subscriptionFeatureCustomTitleBookmarks
            case .folders, .suggestedFolders:
                return L10n.subscriptionFeatureCustomTitleFolders
            default:
                return nil
        }
    }

    @ViewBuilder
    var customAnimation: some View {
        switch self {
            case .deselectChapters, .deselectChapterWhatsNew:
                PreSelectChaptersAnimationView()
            case .upNextShuffle:
                UpNextShuffleAnimationView()
            case .bookmarksLocked, .bookmarksShelfAction:
                BookmarksAnimationView()
            case .folders, .suggestedFolders:
                FoldersAnimationView()
            default:
                EmptyView()
        }
    }
}
