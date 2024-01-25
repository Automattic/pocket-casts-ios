import XCTest
import StoreKitTest

@testable import podcasts
import PocketCastsServer

final class IAPHelperTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    let configurationFile = "Pocket Casts Configuration"

    func testRequestInfo() throws {
        let session = try SKTestSession(configurationFileNamed: configurationFile)
        session.clearTransactions()
        session.resetToDefaultState()
        session.disableDialogs = true

        let helper = IAPHelper()
        let expectation = XCTestExpectation(description: "Fetch Products")
        NotificationCenter.default.addObserver(forName: ServerNotifications.iapProductsUpdated, object: nil, queue: nil) { notification in
            expectation.fulfill()
        }
        helper.requestProductInfo()

        wait(for: [expectation], timeout: 5)
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
        let session = try SKTestSession(configurationFileNamed: configurationFile)
        session.clearTransactions()
        session.resetToDefaultState()
        session.disableDialogs = true

        let helper = IAPHelper()
        SKPaymentQueue.default().add(helper)
        defer {
            SKPaymentQueue.default().remove(helper)
        }
        let expectation = XCTestExpectation(description: "Fetch Products")
        NotificationCenter.default.addObserver(forName: ServerNotifications.iapProductsUpdated, object: nil, queue: nil) { notification in
            expectation.fulfill()
        }
        helper.requestProductInfo()

        wait(for: [expectation], timeout: 5)
        XCTAssert(helper.hasLoadedProducts)

        let buyExpectation = XCTestExpectation(description: "Buy Product")
        NotificationCenter.default.addObserver(forName: ServerNotifications.iapPurchaseCompleted, object: nil, queue: nil) { notification in
            buyExpectation.fulfill()
        }
        let buyResult = helper.buyProduct(identifier: .monthly)
        XCTAssert(buyResult)

        wait(for: [buyExpectation], timeout: 500)

    }

}
