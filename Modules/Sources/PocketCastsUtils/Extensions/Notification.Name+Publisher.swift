import Combine
import Foundation

public extension NSNotification.Name {

    /// Adds some simple to reduce boilerplate when converting a Notification.Name into a publisher
    /// - Parameters:
    ///   - center: The notification center to listen on
    ///   - object: An optional object to listen on
    /// - Returns: A new publisher on the given notification center
    func publisher(in center: NotificationCenter = .default, object: AnyObject? = nil) -> NotificationCenter.Publisher {
        center.publisher(for: self, object: object)
    }
}
