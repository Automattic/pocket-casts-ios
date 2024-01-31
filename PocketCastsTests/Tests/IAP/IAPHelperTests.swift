import XCTest
import StoreKitTest

@testable import podcasts
import PocketCastsServer

final class IAPHelperTests: XCTestCase {
    let configurationFile = "Pocket Casts Configuration"
    let iapTestTimeout: TimeInterval = 5

    var session: SKTestSession!
    var helper: IAPHelper!

    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: configurationFile)
        session.clearTransactions()
        session.resetToDefaultState()
        session.disableDialogs = true

        helper = IAPHelper(serverHandler: MockIAPHandler())
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

    }
}

// MARK: - MockIAPHandler

class MockIAPHandler: IAPHelper.ServerHandler {
    var isLoggedInValue = true
    var iapUnverifiedPurchaseReceiptDateValue: Date?
    var sendPurchaseReceiptSuccess = true
    var isEligible = true

    override var isLoggedIn: Bool {
        isLoggedInValue
    }

    override var iapUnverifiedPurchaseReceiptDate: Date? {
        set {
            iapUnverifiedPurchaseReceiptDateValue = newValue
        }

        get {
            iapUnverifiedPurchaseReceiptDateValue
        }
    }

    override func sendPurchaseReceipt(completion: @escaping (Bool) -> Void) {
        completion(sendPurchaseReceiptSuccess)
    }

    override func checkTrialEligibility(_ base64EncodedReceipt: String, completion: @escaping (_ isEligible: Bool?) -> Void) {
        completion(isEligible)
    }
}
