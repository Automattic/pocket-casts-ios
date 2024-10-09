import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import StoreKit
import UIKit

class IAPHelper: NSObject {
    static let shared = IAPHelper(settings: SettingsProxy(), networking: ApiServerHandler.shared)

    private var productIdentifiers: [IAPProductID] {
        [.monthly, .yearly, .patronMonthly, .patronYearly, .yearlyReferral]
    }
    private var productsArray = [SKProduct]()
    private var requestedPurchase: String!
    private var productsRequest: SKProductsRequest?

    /// Whether or not the user is eligible for an offer
    private(set) var isEligibleForOffer = Constants.Values.offerEligibilityDefaultValue

    /// Prevent multiple eligibility requests from being performed
    private var isCheckingEligibility = false

    /// Prevent multiple product requests from being performed
    private var isRequestingProducts = false

    /// Whether purchasing is allowed in the current environment or not
    private (set) var canMakePurchases = BuildEnvironment.current != .testFlight

    private var settings: IAPHelperSettings
    private var networking: IAPHelperNetworking

    init(settings: IAPHelperSettings, networking: IAPHelperNetworking) {
        self.settings = settings
        self.networking = networking

        super.init()

        addSubscriptionNotifications()
    }

    func setup(hasSubscription: Bool) {
        SKPaymentQueue.default().add(self)
        if !hasSubscription {
            IAPHelper.shared.requestProductInfo()
        }
    }

    func tearDown() {
        SKPaymentQueue.default().remove(self)
    }

    /// Requests the product info if we're not checking already, and the products we have already are different
    func requestProductInfoIfNeeded() {
        let isMissingProducts = productsArray.isEmpty || productsArray.map { $0.productIdentifier } == productIdentifiers.map { $0.rawValue }

        guard isMissingProducts, !isRequestingProducts else {
            return
        }

        requestProductInfo()
    }

    func requestProductInfo() {
        // Don't request if we're already requesting
        guard !isRequestingProducts else { return }

        isRequestingProducts = true
        let request = SKProductsRequest(productIdentifiers: Set(productIdentifiers.map { $0.rawValue }))
        request.delegate = self
        request.start()
    }

    func getProduct(for identifier: IAPProductID) -> SKProduct! {
        guard productsArray.count > 0 else {
            requestProductInfo()
            return nil
        }

        for p in productsArray {
            if p.productIdentifier.caseInsensitiveCompare(identifier.rawValue) == .orderedSame {
                return p
            }
        }
        return nil
    }

    /// Whether the products have been loaded from StoreKit
    var hasLoadedProducts: Bool { productsArray.count > 0 }

    public func getPrice(for identifier: IAPProductID) -> String {
        guard let product = getProduct(for: identifier) else { return "" }

        let numberFormatter = NumberFormatter()
        numberFormatter.formatterBehavior = .behavior10_4
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = product.priceLocale
        let formattedPrice = numberFormatter.string(from: product.price)
        return formattedPrice ?? ""
    }

    public func buyProduct(identifier: IAPProductID, discount: IAPDiscountInfo? = nil) -> Bool {
        guard settings.isLoggedIn, let product = getProduct(for: identifier) else {
            FileLog.shared.addMessage("IAPHelper Failed to initiate purchase of \(identifier)")
            return false
        }

        FileLog.shared.addMessage("IAPHelper Buying \(product.productIdentifier)")
        let payment = SKMutablePayment(product: product)
        if let discount {
            payment.paymentDiscount = SKPaymentDiscount(identifier: discount.identifier, keyIdentifier: discount.key, nonce: discount.uuid, signature: discount.signature, timestamp: NSNumber(integerLiteral: discount.timestamp))
        }
        SKPaymentQueue.default().add(payment)

        return true
    }

    public func getPaymentFrequency(for identifier: IAPProductID) -> String {
        switch identifier {
        case .monthly, .patronMonthly:
            return L10n.month
        case .yearly, .patronYearly, .yearlyReferral:
            return L10n.year
        }
    }

    public func getPriceWithFrequency(for identifier: IAPProductID) -> String? {
        let price = getPrice(for: identifier)
        guard !price.isEmpty else {
            return nil
        }

        switch identifier {
        case .yearly, .patronYearly, .yearlyReferral:
            return L10n.plusYearlyFrequencyPricingFormat(price)
        case .monthly, .patronMonthly:
            return L10n.plusMonthlyFrequencyPricingFormat(price)
        }
    }
}

// MARK: - SKProductsRequestDelegate
extension IAPHelper: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        defer { isRequestingProducts = false }

        if response.products.count > 0 {
            productsArray = response.products

            // Update the trial eligibility
            updateTrialEligibility()

            NotificationCenter.postOnMainThread(notification: ServerNotifications.iapProductsUpdated)
        } else {
            let invalid = response.invalidProductIdentifiers
            for i in invalid {
                FileLog.shared.addMessage("IAPHelper Invalid appstore identifier \(i)")
            }
            NotificationCenter.postOnMainThread(notification: ServerNotifications.iapProductsFailed)
        }
        clearRequestAndHandler()
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        defer { isRequestingProducts = false }
        FileLog.shared.addMessage("IAPHelper Failed to load list of products \(error.localizedDescription)")
        NotificationCenter.postOnMainThread(notification: ServerNotifications.iapProductsFailed)
        clearRequestAndHandler()
    }

    private func clearRequestAndHandler() {
        productsRequest = nil
    }
}

// MARK: - Pricing String Helpers

extension IAPHelper {
    /// Generates a string for a subscription price in the format of PRICE / FREQUENCY
    /// - Parameter product: The product to get the pricing string for
    /// - Returns: The formatted string or nil if the product isn't available or hasn't loaded yet
    func pricingStringWithFrequency(for product: IAPProductID) -> String? {
        let pricing = getPrice(for: product)
        let frequency = getPaymentFrequency(for: product)

        guard !pricing.isEmpty, !frequency.isEmpty else {
            return nil
        }

        return "\(pricing) / \(frequency)"
    }
}

// MARK: - Intro Offers: Free Trials

extension IAPHelper {

    /// Returns a offer description if one is available
    /// - Parameter identifier: the product we want to check for an offer
    /// - Returns: the product offer if available.
    func offerType(_ identifier: IAPProductID) -> PlusPricingInfoModel.ProductOfferType? {
        guard let offer = getFreeTrialOffer(identifier) else {
            return nil
        }
        switch offer.paymentMode {
        case .freeTrial:
            return .freeTrial
        case .payUpFront:
            return .discount
        case .payAsYouGo:
            return nil
        @unknown default:
            return nil
        }
    }
    /// Returns the localized trial duration if there is one
    /// - Parameter identifier: The product to check
    /// - Returns: A formatted string (1 week) or nil if there is no offer available
    func localizedFreeTrialDuration(_ identifier: IAPProductID) -> String? {
        guard let offer = getFreeTrialOffer(identifier) else {
            return nil
        }

        return offer.subscriptionPeriod.localizedPeriodString()
    }

    func localizedFreeTrialDurationAdjective(_ identifier: IAPProductID) -> String? {
        guard let offer = getFreeTrialOffer(identifier) else {
            return nil
        }

        return offer.subscriptionPeriod.localizedPeriodAdjective()
    }


    /// Returns the localized offer price if there is one
    /// - Parameter identifier: The product to check
    /// - Returns: A formatted string ($1) or nil if there is no offer available
    func localizedOfferPrice(_ identifier: IAPProductID) -> String? {
        guard let offer = getFreeTrialOffer(identifier) else {
            return nil
        }

        let numberFormatter = NumberFormatter()
        numberFormatter.formatterBehavior = .behavior10_4
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = offer.priceLocale
        let formattedPrice = numberFormatter.string(from: offer.price)
        return formattedPrice ?? ""
    }

    /// Return the offer localized string for the end date of a product offer
    /// - Parameter identifier: the product id that we want to check the offer
    /// - Returns: the localized string for the end date of a product offer
    func offerEndDate(_ identifier: IAPProductID) -> String? {
        guard let offer = getFreeTrialOffer(identifier) else {
            return nil
        }

        let date = offer.subscriptionPeriod.offerEndDate

        return date?.formatted(date: .long, time: .omitted)
    }

    /// Checks if there is a free trial introductory offer for the given product
    /// - Parameter identifier: The product to check
    /// - Returns: The SKProductDiscount or nil if there is no offer or the user is not eligible for one
    private func getFreeTrialOffer(_ identifier: IAPProductID) -> SKProductDiscount? {
        guard let offer = getProduct(for: identifier)?.introductoryPrice,
            offer.paymentMode == .freeTrial || offer.paymentMode == .payUpFront
        else {
            return nil
        }

        return offer
    }

    /// Checks if there is a promotional offer for this given product
    /// - Parameter identifier: The product to check
    /// - Returns: The SKProductDiscount or nil if there is no offer or the user is not eligible for one
    func getPromoOffer(_ identifier: IAPProductID) -> SKProductDiscount? {
        guard
            let offer = getProduct(for: identifier)?.discounts.filter({ discount in
                discount.type != .introductory
            }).first,
            offer.paymentMode == .freeTrial || offer.paymentMode == .payUpFront
        else {
            return nil
        }

        return offer
    }

    /// Returns the first product ID that has a free trial
    /// The priority order is set by the productIdentifiers array
    private func getFirstFreeTrialProductId() -> IAPProductID? {
        return productIdentifiers.first(where: { getFreeTrialOffer($0) != nil })
    }
}

// MARK: - Trial Eligibility

private extension IAPHelper {
    /// Listens for subscription changes
    private func addSubscriptionNotifications() {
        NotificationCenter.default.addObserver(forName: ServerNotifications.subscriptionStatusChanged, object: nil, queue: .main) { [weak self] _ in
            self?.updateTrialEligibility()
            self?.requestProductInfoIfNeeded()
        }
    }

    /// Update the trial eligibility if:
    /// - We are not already performing a check
    /// - The feature flag is enabled
    /// - A product has a free trial
    /// - The user doesn't have an active subscription
    /// - The receipt exists
    private func updateTrialEligibility() {
        guard
            isCheckingEligibility == false,
            getFirstFreeTrialProductId() != nil,
            SubscriptionHelper.hasActiveSubscription() == false,
            let receiptUrl = Bundle.main.appStoreReceiptURL,
            let receiptString = try? Data(contentsOf: receiptUrl).base64EncodedString()
        else {
            return
        }

        isCheckingEligibility = true
        networking.checkTrialEligibility(receiptString) { [weak self] isEligible in
            let eligible = isEligible ?? Constants.Values.offerEligibilityDefaultValue

            FileLog.shared.addMessage("Refreshed Trial Eligibility: \(eligible ? "Yes" : "No")")
            self?.isEligibleForOffer = eligible
            self?.isCheckingEligibility = false
        }
    }
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
    func purchaseWasSuccessful(_ productId: IAPProductID) {
        trackPaymentEvent(.purchaseSuccessful, productId: productId)
    }

    func purchaseWasCancelled(_ productId: IAPProductID, error: NSError) {
        trackPaymentEvent(.purchaseCancelled, productId: productId, error: error)
    }

    func purchaseFailed(_ productId: IAPProductID, error: NSError) {
        trackPaymentEvent(.purchaseFailed, productId: productId, error: error)
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        FileLog.shared.addMessage("IAPHelper number of transactions in SKPayemntTransaction queue    \(transactions.count)")
        var hasNewPurchasedReceipt = false
        let lowercasedProductIdentifiers = productIdentifiers.map { $0.rawValue.lowercased() }

        for transaction in transactions {
            let product = transaction.payment.productIdentifier
            let transactionDate = DateFormatHelper.sharedHelper.jsonFormat(transaction.transactionDate)
            FileLog.shared.addMessage("IAPHelper Processing transaction with id \(String(describing: transaction.transactionIdentifier)) \(transactionDate))")

            if lowercasedProductIdentifiers.contains(product.lowercased()) {
                switch transaction.transactionState {
                case .purchasing:
                    FileLog.shared.addMessage("IAPHelper Purchasing \(product)")
                case .purchased:
                    hasNewPurchasedReceipt = true
                    queue.finishTransaction(transaction)
                    FileLog.shared.addMessage("IAPHelper Purchase successful for \(product) ")
                case .failed:
                    let e = transaction.error! as NSError
                    FileLog.shared.addMessage("IAPHelper Purchase FAILED for \(product), code=\(e.code) msg= \(e.localizedDescription)/")
                    queue.finishTransaction(transaction)

                    let userInfo = ["error": e]

                    if e.code == 0 || e.code == 2 { // app store couldn't be connected or user cancelled
                        NotificationCenter.postOnMainThread(notification: ServerNotifications.iapPurchaseCancelled, userInfo: userInfo)
                    } else { // report error to user
                        NotificationCenter.postOnMainThread(notification: ServerNotifications.iapPurchaseFailed, userInfo: userInfo)
                    }
                case .deferred:
                    FileLog.shared.addMessage("IAPHelper Purchase deferred for \(product)")
                    NotificationCenter.postOnMainThread(notification: ServerNotifications.iapPurchaseDeferred)
                case .restored:
                    queue.finishTransaction(transaction)
                default:
                    break
                }
            } else {
                FileLog.shared.addMessage("IAPHelper mark non-subscription transaction as finished")
                queue.finishTransaction(transaction)
            }
        }

        if hasNewPurchasedReceipt {
            if settings.iapUnverifiedPurchaseReceiptDate == nil {
                settings.iapUnverifiedPurchaseReceiptDate = Date()
            }

            networking.sendPurchaseReceipt(completion: { success in
                if success {
                    FileLog.shared.addMessage("IAPHelper successfully validated receipt")
                } else {
                    FileLog.shared.addMessage("IAPHelper failed to validate receipt, but as the AppStore purchase was successful mark as Plus user on this device")
                }
            })
            NotificationCenter.postOnMainThread(notification: ServerNotifications.iapPurchaseCompleted)
        }
    }
}

// MARK: - SKProductSubscriptionPeriod Helper Extension

private extension SKProductSubscriptionPeriod {
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
        @unknown default:
            return nil
        }

        return TimePeriodFormatter.format(numberOfUnits: numberOfUnits, unit: calendarUnit)
    }

    func localizedPeriodAdjective() -> String? {
        var localizedUnit: String = "N/A"
        switch unit {
            case .day:
                localizedUnit = L10n.day
            case .week:
                localizedUnit = L10n.week
            case .month:
                localizedUnit = L10n.month
            case .year:
                localizedUnit = L10n.year
        @unknown default:
            localizedUnit = "N/A"
        }
        return "\(self.numberOfUnits)-\(localizedUnit.capitalized)"
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
        @unknown default:
            return nil
        }
        var components = DateComponents()
        components.calendar = Calendar.current
        components.setValue(self.numberOfUnits, for: calendarUnit)

        return Calendar.current.date(byAdding: components, to: Date.now, wrappingComponents: true)
    }
}

private extension IAPHelper {
    func trackPaymentEvent(_ event: AnalyticsEvent, productId: IAPProductID, error: NSError? = nil) {
        let product = getProduct(for: productId)
        var offerType = "none"
        if isEligibleForOffer, let paymentMode = product?.introductoryPrice?.paymentMode {
            if paymentMode == .freeTrial {
                offerType = "free_trial"
            } else if paymentMode == .payUpFront {
                offerType = "intro_offer"
            }
        }

        var properties: [AnyHashable: Any] = ["product": productId.rawValue,
                                              "offer_type": offerType]

        if let error = error {
            properties["error_code"] = error.code
        }

        Analytics.track(event, properties: properties)
    }
}

// MARK: - Dependencies: Settings / Networking
// Defines the settings the IAPHelper needs to read / write
protocol IAPHelperSettings {
    var isLoggedIn: Bool { get }
    var iapUnverifiedPurchaseReceiptDate: Date? { get set }
}

/// Defines the non-storekit network methods the IAPHelper uses
protocol IAPHelperNetworking {
    func sendPurchaseReceipt(completion: @escaping (Bool) -> Void)
    func checkTrialEligibility(_ base64EncodedReceipt: String, completion: @escaping (_ isEligible: Bool?) -> Void)
}

extension ApiServerHandler: IAPHelperNetworking {
    /* Already implements the methods 😎 */
}

private extension IAPHelper {
    /// Acts as a proxy to the `ServerSettings` static methods the IAPHelper uses
    class SettingsProxy: IAPHelperSettings {
        var isLoggedIn: Bool {
            SyncManager.isUserLoggedIn()
        }

        var iapUnverifiedPurchaseReceiptDate: Date? {
            set { ServerSettings.setIapUnverifiedPurchaseReceiptDate(newValue) }
            get { ServerSettings.iapUnverifiedPurchaseReceiptDate() }
        }
    }
}
