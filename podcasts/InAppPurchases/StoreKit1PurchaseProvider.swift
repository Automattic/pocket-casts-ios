import PocketCastsUtils
import StoreKit

/// `PurchaseProvider` backed by the original StoreKit API (`SKPaymentQueue` and `SKProductsRequest`).
final class StoreKit1PurchaseProvider: NSObject, PurchaseProvider {
    private let paymentQueue: SKPaymentQueue
    private let lowercasedProductIdentifiers: Set<String>

    private var products: [SKProduct] = []
    private var productsRequest: SKProductsRequest?
    private var productsCompletion: ((Result<[IAPProduct], Error>) -> Void)?
    private var transactionHandler: (([PurchaseTransactionEvent]) -> Void)?

    /// - Parameter productIdentifiers: the app's subscription products. Transactions for any other product are finished and ignored.
    init(productIdentifiers: [String], paymentQueue: SKPaymentQueue = .default()) {
        self.paymentQueue = paymentQueue
        self.lowercasedProductIdentifiers = Set(productIdentifiers.map { $0.lowercased() })
        super.init()
    }

    // MARK: - PurchaseProvider

    func startObservingTransactions(_ handler: @escaping ([PurchaseTransactionEvent]) -> Void) {
        transactionHandler = handler
        paymentQueue.add(self)
    }

    func stopObservingTransactions() {
        paymentQueue.remove(self)
        transactionHandler = nil
    }

    func requestProducts(ids: [String], completion: @escaping (Result<[IAPProduct], Error>) -> Void) {
        productsCompletion = completion
        let request = SKProductsRequest(productIdentifiers: Set(ids))
        request.delegate = self
        productsRequest = request
        request.start()
    }

    func purchase(productID: String, discount: IAPDiscountInfo?, applicationUsername: String?) -> Bool {
        guard let product = products.first(where: { $0.productIdentifier.caseInsensitiveCompare(productID) == .orderedSame }) else {
            return false
        }

        let payment = SKMutablePayment(product: product)
        if let discount {
            payment.paymentDiscount = SKPaymentDiscount(identifier: discount.identifier, keyIdentifier: discount.key, nonce: discount.uuid, signature: discount.signature, timestamp: NSNumber(integerLiteral: discount.timestamp))
            payment.applicationUsername = applicationUsername
        }
        paymentQueue.add(payment)

        return true
    }

    private func completeProductsRequest(with result: Result<[IAPProduct], Error>) {
        let completion = productsCompletion
        productsCompletion = nil
        productsRequest = nil
        completion?(result)
    }
}

// MARK: - SKProductsRequestDelegate

extension StoreKit1PurchaseProvider: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard !response.products.isEmpty else {
            let invalid = response.invalidProductIdentifiers
            for i in invalid {
                FileLog.shared.addMessage("IAPHelper Invalid appstore identifier \(i)")
            }
            completeProductsRequest(with: .failure(PurchaseProviderError.noProducts(invalidIdentifiers: invalid)))
            return
        }

        products = response.products
        completeProductsRequest(with: .success(response.products.map(IAPProduct.init)))
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        FileLog.shared.addMessage("IAPHelper Failed to load list of products \(error.localizedDescription)")
        completeProductsRequest(with: .failure(error))
    }
}

// MARK: - SKPaymentTransactionObserver

extension StoreKit1PurchaseProvider: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        FileLog.shared.addMessage("IAPHelper number of transactions in SKPayemntTransaction queue    \(transactions.count)")
        var events: [PurchaseTransactionEvent] = []

        for transaction in transactions {
            let product = transaction.payment.productIdentifier
            let discountID = transaction.payment.paymentDiscount?.identifier
            let transactionDate = DateFormatHelper.shared.jsonFormat(transaction.transactionDate)
            FileLog.shared.addMessage("IAPHelper Processing transaction with id \(String(describing: transaction.transactionIdentifier)) \(transactionDate))")

            guard lowercasedProductIdentifiers.contains(product.lowercased()) else {
                FileLog.shared.addMessage("IAPHelper mark non-subscription transaction as finished")
                queue.finishTransaction(transaction)
                continue
            }

            switch transaction.transactionState {
            case .purchasing:
                FileLog.shared.addMessage("IAPHelper Purchasing \(product)")
                events.append(.purchasing(productID: product))
            case .purchased:
                queue.finishTransaction(transaction)
                FileLog.shared.addMessage("IAPHelper Purchase successful for \(product) ")
                events.append(.purchased(productID: product, discountID: discountID))
            case .failed:
                let e = transaction.error! as NSError
                FileLog.shared.addMessage("IAPHelper Purchase FAILED for \(product), code=\(e.code) msg= \(e.localizedDescription)/")
                queue.finishTransaction(transaction)

                if e.code == SKError.Code.unknown.rawValue || e.code == SKError.Code.paymentCancelled.rawValue { // app store couldn't be connected or user cancelled
                    events.append(.cancelled(productID: product, discountID: discountID, error: e))
                } else { // report error to user
                    events.append(.failed(productID: product, discountID: discountID, error: e))
                }
            case .deferred:
                FileLog.shared.addMessage("IAPHelper Purchase deferred for \(product)")
                events.append(.deferred(productID: product))
            case .restored:
                queue.finishTransaction(transaction)
                events.append(.restored(productID: product))
            @unknown default:
                break
            }
        }

        transactionHandler?(events)
    }
}

// MARK: - Mapping

private extension IAPProduct {
    init(_ product: SKProduct) {
        self.init(
            id: product.productIdentifier,
            price: product.price.decimalValue,
            priceLocale: product.priceLocale,
            subscriptionPeriod: product.subscriptionPeriod.flatMap(SubscriptionPeriod.init),
            introductoryOffer: product.introductoryPrice.flatMap(IntroductoryOffer.init)
        )
    }
}

private extension IAPProduct.SubscriptionPeriod {
    init?(_ period: SKProductSubscriptionPeriod) {
        let unit: Unit
        switch period.unit {
        case .day:
            unit = .day
        case .week:
            unit = .week
        case .month:
            unit = .month
        case .year:
            unit = .year
        @unknown default:
            return nil
        }
        self.init(unit: unit, numberOfUnits: period.numberOfUnits)
    }
}

private extension IAPProduct.IntroductoryOffer {
    init?(_ discount: SKProductDiscount) {
        let paymentMode: PaymentMode
        switch discount.paymentMode {
        case .freeTrial:
            paymentMode = .freeTrial
        case .payUpFront:
            paymentMode = .payUpFront
        case .payAsYouGo:
            paymentMode = .payAsYouGo
        @unknown default:
            return nil
        }
        guard let period = IAPProduct.SubscriptionPeriod(discount.subscriptionPeriod) else {
            return nil
        }
        self.init(paymentMode: paymentMode, price: discount.price.decimalValue, priceLocale: discount.priceLocale, subscriptionPeriod: period)
    }
}
