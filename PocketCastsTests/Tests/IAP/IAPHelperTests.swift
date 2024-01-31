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
        let expectation = XCTestExpectation(description: "Fetch Products")
        NotificationCenter.default.addObserver(forName: ServerNotifications.iapProductsUpdated, object: nil, queue: nil) { notification in
            expectation.fulfill()
        }
        helper.requestProductInfo()

        wait(for: [expectation], timeout: iapTestTimeout)
        XCTAssert(helper.hasLoadedProducts)

        let _ = helper.getProduct(for: .monthly)

        let price = helper.getPrice(for: .monthly)
        XCTAssertEqual(price, "$3.99")

        let priceWithFrequency = helper.getPriceWithFrequency(for: .monthly)
        XCTAssertEqual(priceWithFrequency, "$3.99 per month")

        let paymentFrequency = helper.getPaymentFrequency(for: .monthly)
        XCTAssertEqual(paymentFrequency, "month")
    }

    func testPurchase() throws {
        let expectation = XCTestExpectation(description: "Fetch Products")
        NotificationCenter.default.addObserver(forName: ServerNotifications.iapProductsUpdated, object: nil, queue: nil) { notification in
            expectation.fulfill()
        }
        helper.requestProductInfo()

        wait(for: [expectation], timeout: iapTestTimeout)
        XCTAssert(helper.hasLoadedProducts)

        let buyExpectation = XCTestExpectation(description: "Buy Product")
        NotificationCenter.default.addObserver(forName: ServerNotifications.iapPurchaseCompleted, object: nil, queue: nil) { notification in
            buyExpectation.fulfill()
        }
        let buyResult = helper.buyProduct(identifier: .monthly)
        XCTAssert(buyResult)

        wait(for: [buyExpectation], timeout: iapTestTimeout)

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
