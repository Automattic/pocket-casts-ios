import Foundation

/// A change to a subscription transaction, reported by a `PurchaseProvider`.
/// The provider has already finished the transaction where needed, and only reports the app's own products.
enum PurchaseTransactionEvent {
    case purchasing(productID: String)
    case purchased(productID: String, discountID: String?)
    /// The user cancelled, or the App Store couldn't be reached.
    case cancelled(productID: String, discountID: String?, error: NSError)
    case failed(productID: String, discountID: String?, error: NSError)
    /// Waiting on an external action, such as Ask to Buy.
    case deferred(productID: String)
    case restored(productID: String)
}

/// The StoreKit engine behind `IAPHelper`: loads products, starts purchases and observes transactions.
protocol PurchaseProvider: AnyObject {
    /// Starts listening for transactions. The handler gets each batch of events and can be called on any thread.
    func startObservingTransactions(_ handler: @escaping ([PurchaseTransactionEvent]) -> Void)

    func stopObservingTransactions()

    /// Loads the products for the given ids. The completion can be called on any thread.
    func requestProducts(ids: [String], completion: @escaping (Result<[IAPProduct], Error>) -> Void)

    /// Starts a purchase of a product returned by `requestProducts`. The result arrives through the transaction handler.
    /// - Returns: `false` if the purchase couldn't be started.
    func purchase(productID: String, discount: IAPDiscountInfo?, applicationUsername: String?) -> Bool
}

enum PurchaseProviderError: Error {
    /// The App Store returned no products, only invalid identifiers.
    case noProducts(invalidIdentifiers: [String])
}
