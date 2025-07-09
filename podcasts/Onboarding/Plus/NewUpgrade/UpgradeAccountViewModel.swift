class UpgradeAccountViewModel: PlusPricingInfoModel {

    @Published var upgradeTier: UpgradeTier = .plus
    @Published var selectedProduct: IAPProductID = .yearly
    @Published var products: [PlusProductPricingInfo] = []

    @Published private(set) var selectedFrequency: PlanFrequency = .yearly

    init(upgradeTier: UpgradeTier = .plus, selectedProduct: IAPProductID = .yearly) {
        self.upgradeTier = upgradeTier
        self.selectedProduct = selectedProduct
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
        guard let product = pricingInfo.products.first(where: {$0.identifier == selectedProduct}) else {
            return false
        }
        guard let offer = product.offer else {
            return false
        }

        return offer.type == .freeTrial
    }

    var timelineEvents: [TimelineEvent] {
        guard let product = pricingInfo.products.first(where: {$0.identifier == selectedProduct}),
              let offer = product.offer, offer.type == .freeTrial
        else {
            return []
        }
        var events = [TimelineEvent]()


        let todayEvent = TimelineEvent(iconName: "unlocked-large", title: L10n.today, detail: L10n.upgradeAccountTimelineDay1, date: Date.now)
        events.append(todayEvent)

        let oneWeekBeforeEvent = TimelineEvent(iconName: "mail", title: "Day 24", detail: L10n.upgradeAccountTimelineWeekBefore, date: Date.now + 3600)
        events.append(oneWeekBeforeEvent)

        let chargingEvent = TimelineEvent(iconName: "star_empty", title: offer.dateAfterOffer, detail: L10n.upgradeAccountTimelineChargingDay(offer.dateAfterOffer), date: Date.now + (3600 * 2))

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
