import Foundation
import PocketCastsUtils
import XCTest

final class NotificationMainThreadTests: XCTestCase {
    func test_notification_posts_on_main_thread() {
        expectation(forNotification: .myAwesomeNotification, object: nil) { _ in
            XCTAssertTrue(Thread.isMainThread)
            return true
        }

        DispatchQueue.global(qos: .default).sync {
            NotificationCenter.postOnMainThread(notification: .myAwesomeNotification, object: nil, userInfo: nil)
        }

        waitForExpectations(timeout: 1)
    }

    func test_notification_posts_on_object() {
        let object = NotificationObjectTest(identifier: "Hello")

        expectation(forNotification: .myAwesomeNotification, object: object) { notification in
            XCTAssertEqual(notification.object as! NotificationObjectTest, object)
            return true
        }

        NotificationCenter.postOnMainThread(notification: .myAwesomeNotification, object: object, userInfo: nil)
        waitForExpectations(timeout: 1)
    }

    func test_notification_passes_user_info() {
        let userInfo: [AnyHashable: String] = ["hello": "world"]

        expectation(forNotification: .myAwesomeNotification, object: nil) { notification in
            guard let notificationInfo = try? XCTUnwrap(notification.userInfo) as? [AnyHashable: String] else {
                return false
            }

            XCTAssert(notificationInfo["hello"] == userInfo["hello"])
            return true
        }

        NotificationCenter.postOnMainThread(notification: .myAwesomeNotification, object: nil, userInfo: userInfo)
        waitForExpectations(timeout: 1)
    }
}

private extension Notification.Name {
    static var myAwesomeNotification = Notification.Name("Unit.Testing.Is.Awesome")
}

private class NotificationObjectTest: Equatable {
    let identifier: String
    init(identifier: String) {
        self.identifier = identifier
    }

    static func == (lhs: NotificationObjectTest, rhs: NotificationObjectTest) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
