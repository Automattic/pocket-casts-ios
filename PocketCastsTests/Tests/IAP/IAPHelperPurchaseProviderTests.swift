import XCTest

@testable import podcasts
import PocketCastsServer

final class IAPHelperPurchaseProviderTests: XCTestCase {
    private var provider: MockPurchaseProvider!
    private var dependencies: MockIAPDependencies!
    private var helper: IAPHelper!

    override func setUp() {
        super.setUp()
        provider = MockPurchaseProvider()
        dependencies = MockIAPDependencies()
        helper = IAPHelper(settings: dependencies, networking: dependencies, provider: provider)
        helper.setup(hasSubscription: true)
    }

    override func tearDown() {
        helper.tearDown()
        helper = nil
        provider = nil
        dependencies = nil
        super.tearDown()
    }

    // MARK: - Products

    func testSetupStartsObservingTransactions() {
        XCTAssertTrue(provider.isObserving)

        helper.tearDown()

        XCTAssertFalse(provider.isObserving)
    }

    func testLoadingProductsPostsUpdatedAndFormatsPrices() {
        loadProducts()

        XCTAssertTrue(helper.hasLoadedProducts)
        XCTAssertEqual(provider.requestedIDs, IAPHelper.productIdentifiers.map(\.rawValue))
        XCTAssertEqual(helper.getPrice(for: .monthly), "$3.99")
        XCTAssertEqual(helper.getPrice(for: .yearly), "$39.99")
        XCTAssertEqual(helper.getMonthlyPrice(for: .yearly), "$3.33")
        XCTAssertEqual(helper.getWeeklyPrice(for: .monthly), "$0.92")
        XCTAssertEqual(helper.getWeeklyReferencePrice(for: .yearly) ?? 0, 39.99 / 52, accuracy: 0.0001)
    }

    func testFailingToLoadProductsPostsFailed() {
        provider.productsResult = .failure(PurchaseProviderError.noProducts(invalidIdentifiers: []))
        let failed = expectation(forNotification: ServerNotifications.iapProductsFailed, object: nil)

        helper.requestProductInfo()

        wait(for: [failed], timeout: 1)
        XCTAssertFalse(helper.hasLoadedProducts)
        XCTAssertEqual(helper.getPrice(for: .monthly), "")
    }

    func testIntroductoryOfferInfo() {
        loadProducts()

        XCTAssertEqual(helper.offerType(.yearly), .freeTrial)
        XCTAssertEqual(helper.localizedOfferPrice(.yearly), "$0.00")
        XCTAssertNotNil(helper.localizedFreeTrialDuration(.yearly))
        XCTAssertNotNil(helper.offerEndDate(.yearly))

        XCTAssertEqual(helper.offerType(.patronYearly), .discount)
        XCTAssertEqual(helper.localizedOfferPrice(.patronYearly), "$9.99")

        XCTAssertNil(helper.offerType(.monthly))
        XCTAssertNil(helper.localizedFreeTrialDuration(.monthly))
    }

    // MARK: - Purchasing

    func testBuyProductStartsPurchaseWithDiscount() {
        loadProducts()
        let discount = IAPDiscountInfo(identifier: "offer", uuid: UUID(), timestamp: 1, key: "key", signature: "signature")

        XCTAssertTrue(helper.buyProduct(identifier: .yearly, discount: discount))

        XCTAssertEqual(provider.purchasedProductID, IAPProductID.yearly.rawValue)
        XCTAssertEqual(provider.purchasedDiscount?.identifier, "offer")
    }

    func testBuyProductFailsWhenLoggedOut() {
        loadProducts()
        dependencies.isLoggedIn = false

        XCTAssertFalse(helper.buyProduct(identifier: .yearly))
        XCTAssertNil(provider.purchasedProductID)
    }

    func testBuyProductFailsWhenProductsAreNotLoaded() {
        XCTAssertFalse(helper.buyProduct(identifier: .yearly))
        XCTAssertNil(provider.purchasedProductID)
    }

    // MARK: - Transactions

    func testPurchasedTransactionSendsReceiptAndPostsCompleted() {
        let completed = expectation(forNotification: ServerNotifications.iapPurchaseCompleted, object: nil)

        provider.send([.purchased(productID: IAPProductID.monthly.rawValue, discountID: nil)])

        wait(for: [completed], timeout: 1)
        XCTAssertEqual(dependencies.sendPurchaseReceiptCount, 1)
        XCTAssertNotNil(dependencies.iapUnverifiedPurchaseReceiptDate)
    }

    func testSeveralPurchasesInOneBatchSendTheReceiptOnce() {
        let completed = expectation(forNotification: ServerNotifications.iapPurchaseCompleted, object: nil)

        provider.send([
            .purchased(productID: IAPProductID.monthly.rawValue, discountID: nil),
            .purchased(productID: IAPProductID.yearly.rawValue, discountID: nil)
        ])

        wait(for: [completed], timeout: 1)
        XCTAssertEqual(dependencies.sendPurchaseReceiptCount, 1)
    }

    func testCancelledTransactionPostsCancelled() {
        let cancelled = expectation(forNotification: ServerNotifications.iapPurchaseCancelled, object: nil)

        provider.send([.cancelled(productID: IAPProductID.monthly.rawValue, discountID: nil, error: NSError(domain: "test", code: 2))])

        wait(for: [cancelled], timeout: 1)
        XCTAssertEqual(dependencies.sendPurchaseReceiptCount, 0)
    }

    func testFailedTransactionPostsFailed() {
        let failed = expectation(forNotification: ServerNotifications.iapPurchaseFailed, object: nil)

        provider.send([.failed(productID: IAPProductID.monthly.rawValue, discountID: nil, error: NSError(domain: "test", code: 5))])

        wait(for: [failed], timeout: 1)
        XCTAssertEqual(dependencies.sendPurchaseReceiptCount, 0)
    }

    func testDeferredTransactionPostsDeferred() {
        let deferred = expectation(forNotification: ServerNotifications.iapPurchaseDeferred, object: nil)

        provider.send([.deferred(productID: IAPProductID.monthly.rawValue)])

        wait(for: [deferred], timeout: 1)
        XCTAssertEqual(dependencies.sendPurchaseReceiptCount, 0)
    }

    // MARK: - Helpers

    private func loadProducts() {
        let updated = expectation(forNotification: ServerNotifications.iapProductsUpdated, object: nil)
        helper.requestProductInfo()
        wait(for: [updated], timeout: 1)
    }
}

// MARK: - Mocks

private final class MockPurchaseProvider: PurchaseProvider {
    private static let locale = Locale(identifier: "en_US")
    private static let year = IAPProduct.SubscriptionPeriod(unit: .year, numberOfUnits: 1)
    private static let month = IAPProduct.SubscriptionPeriod(unit: .month, numberOfUnits: 1)

    var productsResult: Result<[IAPProduct], Error> = .success([
        IAPProduct(id: IAPProductID.monthly.rawValue, price: Decimal(string: "3.99")!, priceLocale: locale, subscriptionPeriod: month, introductoryOffer: nil),
        IAPProduct(id: IAPProductID.yearly.rawValue, price: Decimal(string: "39.99")!, priceLocale: locale, subscriptionPeriod: year,
                   introductoryOffer: .init(paymentMode: .freeTrial, price: 0, priceLocale: locale, subscriptionPeriod: .init(unit: .month, numberOfUnits: 1))),
        IAPProduct(id: IAPProductID.patronYearly.rawValue, price: Decimal(string: "99.99")!, priceLocale: locale, subscriptionPeriod: year,
                   introductoryOffer: .init(paymentMode: .payUpFront, price: Decimal(string: "9.99")!, priceLocale: locale, subscriptionPeriod: year))
    ])

    private(set) var isObserving = false
    private(set) var requestedIDs: [String]?
    private(set) var purchasedProductID: String?
    private(set) var purchasedDiscount: IAPDiscountInfo?
    private var transactionHandler: (([PurchaseTransactionEvent]) -> Void)?

    func send(_ events: [PurchaseTransactionEvent]) {
        transactionHandler?(events)
    }

    func startObservingTransactions(_ handler: @escaping ([PurchaseTransactionEvent]) -> Void) {
        isObserving = true
        transactionHandler = handler
    }

    func stopObservingTransactions() {
        isObserving = false
        transactionHandler = nil
    }

    func requestProducts(ids: [String], completion: @escaping (Result<[IAPProduct], Error>) -> Void) {
        requestedIDs = ids
        completion(productsResult)
    }

    func purchase(productID: String, discount: IAPDiscountInfo?, applicationUsername: String?) -> Bool {
        purchasedProductID = productID
        purchasedDiscount = discount
        return true
    }
}

private final class MockIAPDependencies: IAPHelperSettings, IAPHelperNetworking {
    var isLoggedIn = true
    var iapUnverifiedPurchaseReceiptDate: Date?
    private(set) var sendPurchaseReceiptCount = 0

    func sendPurchaseReceipt(completion: @escaping (Bool) -> Void) {
        sendPurchaseReceiptCount += 1
        completion(true)
    }

    func checkTrialEligibility(_ base64EncodedReceipt: String, completion: @escaping (_ isEligible: Bool?) -> Void) {
        completion(true)
    }
}
