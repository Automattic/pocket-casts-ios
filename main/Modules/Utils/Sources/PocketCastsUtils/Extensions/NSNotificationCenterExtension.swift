import Foundation

public extension NotificationCenter {
    static func postOnMainThread(notification: Notification.Name) {
        if Thread.isMainThread {
            NotificationCenter.default.post(name: notification, object: nil)
        }
        else {
            DispatchQueue.main.sync { () in
                NotificationCenter.default.post(name: notification, object: nil)
            }
        }
    }
    
    static func postOnMainThread(notification: Notification.Name, object: Any?) {
        if Thread.isMainThread {
            NotificationCenter.default.post(name: notification, object: object)
        }
        else {
            DispatchQueue.main.sync { () in
                NotificationCenter.default.post(name: notification, object: object)
            }
        }
    }
}
