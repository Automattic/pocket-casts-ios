import Foundation
import PocketCastsUtils

/// A StoreKit-agnostic description of a subscription product.
/// Each `PurchaseProvider` maps its own product type into this, so `IAPHelper` never touches StoreKit types.
struct IAPProduct: Equatable {
    let id: String
    let price: Decimal
    let priceLocale: Locale
    let subscriptionPeriod: SubscriptionPeriod?
    let introductoryOffer: IntroductoryOffer?

    struct SubscriptionPeriod: Equatable {
        enum Unit: Equatable {
            case day, week, month, year
        }

        let unit: Unit
        let numberOfUnits: Int
    }

    struct IntroductoryOffer: Equatable {
        enum PaymentMode: Equatable {
            case freeTrial, payUpFront, payAsYouGo
        }

        let paymentMode: PaymentMode
        let price: Decimal
        let priceLocale: Locale
        let subscriptionPeriod: SubscriptionPeriod
    }
}

// MARK: - SubscriptionPeriod formatting

extension IAPProduct.SubscriptionPeriod {
    /// Converts the period into a localized readable format, ie: 3 days, 1 month, 1 year, etc.
    /// - Returns: Localized formatted version of the subscription period
    func localizedPeriodString() -> String? {
        let calendarUnit: NSCalendar.Unit
        switch unit {
        case .day:
            calendarUnit = .day
        case .week:
            calendarUnit = .weekOfMonth
        case .month:
            calendarUnit = .month
        case .year:
            calendarUnit = .year
        }

        return TimePeriodFormatter.format(numberOfUnits: numberOfUnits, unit: calendarUnit)
    }

    func localizedPeriodAdjective() -> String {
        let localizedUnit: String
        switch unit {
        case .day:
            localizedUnit = L10n.day
        case .week:
            localizedUnit = L10n.week
        case .month:
            localizedUnit = L10n.month
        case .year:
            localizedUnit = L10n.year
        }
        return "\(numberOfUnits)-\(localizedUnit.capitalized)"
    }

    /// Return the date when the offer price ends if an offer is available and is time bound
    var offerEndDate: Date? {
        let calendarUnit: Calendar.Component
        switch unit {
        case .day:
            calendarUnit = .day
        case .week:
            calendarUnit = .weekOfMonth
        case .month:
            calendarUnit = .month
        case .year:
            calendarUnit = .year
        }
        var components = DateComponents()
        components.calendar = Calendar.current
        components.setValue(numberOfUnits, for: calendarUnit)

        return Calendar.current.date(byAdding: components, to: Date.now, wrappingComponents: true)
    }
}
