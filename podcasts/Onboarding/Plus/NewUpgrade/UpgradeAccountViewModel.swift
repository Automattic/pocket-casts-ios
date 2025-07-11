class UpgradeAccountViewModel: PlusPurchaseModel {

    @Published var upgradeTier: UpgradeTier = .plus
    @Published var selectedProduct: IAPProductID = .yearly
    @Published var products: [PlusProductPricingInfo] = []

    @Published private(set) var selectedFrequency: PlanFrequency = .yearly

    let viewSource: PlusUpgradeViewSource

    init(upgradeTier: UpgradeTier = .plus, selectedProduct: IAPProductID = .yearly, viewSource: PlusUpgradeViewSource = .unknown) {
        self.upgradeTier = upgradeTier
        self.selectedProduct = selectedProduct
        self.viewSource = viewSource
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
}

extension UpgradeAccountViewModel {
    static func make(in navigationController: UINavigationController? = nil, plan: Plan, frequency: PlanFrequency, viewSource: PlusUpgradeViewSource, customTitle: String? = nil) -> UIViewController {
        let viewModel = UpgradeAccountViewModel(upgradeTier: plan.tier, selectedProduct: product(for: plan, frequency: frequency), viewSource: viewSource)

        let view = UpgradeAccountView(model: viewModel)
        let controller = ThemedHostingController(rootView: view)
        controller.modalPresentationStyle = .fullScreen

        return controller
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
