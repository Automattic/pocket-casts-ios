import UIKit
import PocketCastsServer
import PocketCastsUtils

/// A parent model that allows a view to present pricing information
class PlusPricingInfoModel: ObservableObject {
    // Allow injection of the IapHelper
    let purchaseHandler: IAPHelper

    // Allow our views to get the necessary pricing information
    @Published var pricingInfo: PlusPricingInfo

    /// Determines whether prices are available
    @Published var priceAvailability: PriceAvailablity

    class var availableProductIds: [IAPProductID] {
        return [.yearly, .monthly, .patronYearly, .patronMonthly]
    }

    init(purchaseHandler: IAPHelper = .shared) {
        self.purchaseHandler = purchaseHandler
        self.pricingInfo = Self.getPricingInfo(from: purchaseHandler)
        self.priceAvailability = purchaseHandler.hasLoadedProducts ? .available : .unknown
    }

    private static func getPricingInfo(from purchaseHandler: IAPHelper) -> PlusPricingInfo {
        var pricing: [PlusProductPricingInfo] = []

        for product in availableProductIds {
            let basePrice = purchaseHandler.getWeeklyReferencePrice(for: product)
            let price = purchaseHandler.getPriceWithFrequency(for: product) ?? ""
            let rawPrice = purchaseHandler.getPrice(for: product)
            let weeklyPrice = purchaseHandler.getWeeklyPrice(for: product)
            let monthlyPrice = product.isYearlyProduct ? purchaseHandler.getMonthlyPrice(for: product) : nil
            var offer: ProductOfferInfo?
            if purchaseHandler.isEligibleForOffer,
               let duration = purchaseHandler.localizedFreeTrialDuration(product),
               let type = purchaseHandler.offerType(product),
               let price = purchaseHandler.localizedOfferPrice(product),
               let offerEndDateLocalized = purchaseHandler.offerEndDateLocalized(product),
               let offerEndDate = purchaseHandler.offerEndDate(product) {
                offer = ProductOfferInfo(type: type, duration: duration, price: price, rawPrice: rawPrice, offerEndDate: offerEndDate, offerEndDateLocalized: offerEndDateLocalized)
            }

            let info = PlusProductPricingInfo(identifier: product,
                                              price: price,
                                              rawPrice: rawPrice,
                                              weeklyPrice: weeklyPrice,
                                              monthlyPrice: monthlyPrice,
                                              offer: offer,
                                              basePrice: basePrice ?? 0)
            pricing.append(info)
        }

        // Sort any products with free trials to the top of the list
        pricing.sort { $0.offer != nil && $1.offer == nil }

        return PlusPricingInfo(products: pricing)
    }

    // A simple struct to keep track of the product and pricing information the view needs
    struct PlusPricingInfo {
        let products: [PlusProductPricingInfo]
        var hasOffer: Bool {
           products.contains(where: { $0.offer != nil } )
        }
    }

    struct PlusProductPricingInfo: Identifiable {
        let identifier: IAPProductID
        let price: String
        let rawPrice: String
        let weeklyPrice: String
        let monthlyPrice: String?
        let offer: ProductOfferInfo?

        let basePrice: Double

        var id: String { identifier.rawValue }
    }

    enum ProductOfferType {
        case freeTrial
        case discount
    }

    struct ProductOfferInfo {
        let type: ProductOfferType
        let duration: String
        let price: String
        let rawPrice: String
        let offerEndDate: Date?
        let offerEndDateLocalized: String

        var title: String {
            switch type {
            case .freeTrial:
                return L10n.plusStartMyFreeTrial
            case .discount:
                return L10n.plusDiscountYearlyMembership
            }
        }

        var description: String {
            switch type {
            case .freeTrial:
                return L10n.plusFreeMembershipFormat(duration)
            case .discount:
                return L10n.plusDiscountYearlyMembership
            }
        }

        var terms: String {
            switch type {
            case .freeTrial:
                return L10n.pricingTermsAfterTrialLong(duration, offerEndDateLocalized.nonBreakingSpaces())
            case .discount:
                return L10n.pricingTermsAfterDiscount(rawPrice, duration, offerEndDateLocalized.nonBreakingSpaces())
            }
        }

    }

    enum PriceAvailablity {
        case unknown, available, loading, failed
    }

    func pricingInfo(for tier: UpgradeTier, frequency: PlanFrequency) -> PlusProductPricingInfo? {
        guard let pricingInfo = product(for: tier.plan, frequency: frequency) else {
            return nil
        }
        return pricingInfo
    }

    func product(for plan: Plan, frequency: PlanFrequency) -> PlusProductPricingInfo? {
        pricingInfo.products.first(where: { $0.identifier == (frequency == .yearly ? plan.yearly : plan.monthly) })
    }

    func product(for productID: IAPProductID) -> PlusProductPricingInfo? {
        pricingInfo.products.first(where: { $0.identifier == productID })
    }
}

// MARK: - Price Loading
extension PlusPricingInfoModel {
    func loadPrices(_ completion: (() -> Void)? = nil) {
        if purchaseHandler.hasLoadedProducts {
            priceAvailability = .available
            if FeatureFlag.newOfferEligibilityCheck.enabled {
                purchaseHandler.updateTrialEligibility() { [weak self] in
                    guard let self else { return }
                    self.pricingInfo = Self.getPricingInfo(from: purchaseHandler)
                    completion?()
                }
            } else {
                self.pricingInfo = Self.getPricingInfo(from: purchaseHandler)
                completion?()
            }
            return
        }

        priceAvailability = .loading

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(forName: ServerNotifications.iapProductsUpdated, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            if FeatureFlag.newOfferEligibilityCheck.enabled {
                purchaseHandler.updateTrialEligibility() { [weak self] in
                    guard let self else { return }
                    priceAvailability = .available
                    pricingInfo = Self.getPricingInfo(from: purchaseHandler)
                    completion?()
                }
            } else {
                priceAvailability = .available
                pricingInfo = Self.getPricingInfo(from: purchaseHandler)
                completion?()
            }
        }

        notificationCenter.addObserver(forName: ServerNotifications.iapProductsFailed, object: nil, queue: .main) { _ in
            self.priceAvailability = .failed
            completion?()
        }

        purchaseHandler.requestProductInfo()
    }
}
