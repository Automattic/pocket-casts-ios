import UIKit

class SubscriptionHelper: NSObject {
    class func hasActiveSubscription() -> Bool {
        let status = UserDefaults.standard.bool(forKey: Constants.Values.subscriptionPaid)
        return status
    }

    class func hasRenewingSubscription() -> Bool {
        let status = UserDefaults.standard.bool(forKey: Constants.Values.subscriptionAutoRenewing)
        return status
    }

    class func subscriptionGiftDays() -> Int {
        let days = UserDefaults.standard.integer(forKey: Constants.Values.subscriptionGiftDays)
        return days
    }

    class func subscriptionPlatform() -> Int {
        let platform = UserDefaults.standard.integer(forKey: Constants.Values.subscriptionPlatform)
        return platform
    }

    class func subscriptionRenewalDate() -> Date? {
        let renewalTimeInterval = UserDefaults.standard.integer(forKey: Constants.Values.subscriptionExpiryDate)
        let renewalDate = Date(timeIntervalSince1970: TimeInterval(renewalTimeInterval))
        return renewalDate
    }

    class func timeToSubscriptionExpiry() -> TimeInterval? {
        if !hasRenewingSubscription() {
            let renewalTimeInterval = UserDefaults.standard.integer(forKey: Constants.Values.subscriptionExpiryDate)
            if renewalTimeInterval == 0 { return nil } // we can't calculate an offset to an non-existent time

            let expiryDate = Date(timeIntervalSince1970: TimeInterval(renewalTimeInterval))
            let expiryTime = expiryDate.timeIntervalSinceNow
            return expiryTime
        }
        return nil
    }

    class func subscriptionFrequency() -> String {
        let frequency = UserDefaults.standard.integer(forKey: Constants.Values.subscriptionFrequency)
        switch frequency {
        case SubscriptionFrequency.monthly.rawValue:
            return "Monthly"
        case SubscriptionFrequency.yearly.rawValue:
            return "Yearly"
        default:
            return ""
        }
    }

    class func hasLifetimeGift() -> Bool {
        guard SubscriptionHelper.subscriptionPlatform() == SubscriptionPlatform.gift.rawValue else { return false }
        let days = UserDefaults.standard.integer(forKey: Constants.Values.subscriptionGiftDays)
        let tenYearsInDays = 10 * 365
        return days > tenYearsInDays
    }
}
