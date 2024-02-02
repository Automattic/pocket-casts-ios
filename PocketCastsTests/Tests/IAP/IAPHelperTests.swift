import XCTest
import StoreKitTest

@testable import podcasts
import PocketCastsServer

final class IAPHelperTests: XCTestCase {
    let configurationFile = "Pocket Casts Configuration"
    let iapTestTimeout: TimeInterval = 5

    private var session: SKTestSession!
    private var helper: IAPHelper!
    private var handler: MockIAPHandler!

    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: configurationFile)
        session.clearTransactions()
        session.resetToDefaultState()
        session.disableDialogs = true

        handler = MockIAPHandler()
        helper = IAPHelper(settings: handler, networking: handler)

        SKPaymentQueue.default().add(helper)
    }

    override func tearDownWithError() throws {
        session.clearTransactions()
        SKPaymentQueue.default().remove(helper)
    }

    func testRequestInfo() throws {
        helper.requestProductInfo()
        wait(for: ServerNotifications.iapProductsUpdated, timeout: iapTestTimeout, description: "Fetch Products")

        let price = helper.getPrice(for: .monthly)
        XCTAssertEqual(price, "$3.99")

        let priceWithFrequency = helper.getPriceWithFrequency(for: .monthly)
        XCTAssertEqual(priceWithFrequency, "$3.99 per month")

        let paymentFrequency = helper.getPaymentFrequency(for: .monthly)
        XCTAssertEqual(paymentFrequency, "month")
    }

    func testPurchase() throws {
        helper.requestProductInfo()
        wait(for: ServerNotifications.iapProductsUpdated, timeout: iapTestTimeout, description: "Fetch Products")

        XCTAssert(helper.hasLoadedProducts)

        let buyResult = helper.buyProduct(identifier: .monthly)
        XCTAssert(buyResult)

        wait(for: ServerNotifications.iapPurchaseCompleted, timeout: iapTestTimeout, description: "Buy Products")

        XCTAssertEqual(session.allTransactions().first?.productIdentifier, IAPProductID.monthly.rawValue)
    }
}

// MARK: - MockIAPHandler

private class MockIAPHandler: IAPHelperSettings, IAPHelperNetworking {
    var isLoggedInValue = true
    var iapUnverifiedPurchaseReceiptDateValue: Date?
    var sendPurchaseReceiptSuccess = true
    var isEligible = true

    var isLoggedIn: Bool {
        isLoggedInValue
    }

    var iapUnverifiedPurchaseReceiptDate: Date? {
        set {
            iapUnverifiedPurchaseReceiptDateValue = newValue
        }

        get {
            iapUnverifiedPurchaseReceiptDateValue
        }
    }

    func sendPurchaseReceipt(completion: @escaping (Bool) -> Void) {
        completion(sendPurchaseReceiptSuccess)
    }

    func checkTrialEligibility(_ base64EncodedReceipt: String, completion: @escaping (_ isEligible: Bool?) -> Void) {
        completion(isEligible)
    }
}
