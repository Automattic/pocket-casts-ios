import Foundation

public extension NotificationCenter {
    static func postOnMainThread(notification: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        guard Thread.isMainThread else {
            DispatchQueue.main.sync {
                Self.postOnMainThread(notification: notification, object: object, userInfo: userInfo)
            }
            return
        }

        NotificationCenter.default.post(name: notification, object: object, userInfo: userInfo)
    }
}
