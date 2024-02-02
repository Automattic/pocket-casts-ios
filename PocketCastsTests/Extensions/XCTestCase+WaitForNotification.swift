import XCTest

extension XCTestCase {
    /// Reduces the boilerplate of waiting for a notification expectation to fire into 1 line
    /// wait(for: .helloWorld, decription: "Hello, of worlds")
    func wait(for notification: Notification.Name, object: Any? = nil, notificationCenter: NotificationCenter = .default, timeout: TimeInterval = 1, description: String) {
        let expectation = XCTNSNotificationExpectation(name: notification, object: object, notificationCenter: .default)
        expectation.expectationDescription = description

        wait(for: [expectation], timeout: timeout)
    }
}
