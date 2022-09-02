import Foundation

public extension NotificationCenter {
    static func postOnMainThread(notification: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        if Thread.isMainThread {
            NotificationCenter.default.post(name: notification, object: object, userInfo: userInfo)
            return
        }

        // Force the notification to be posted on the main thread
        DispatchQueue.main.sync {
            Self.postOnMainThread(notification: notification, object: object, userInfo: userInfo)
        }
    }
}
