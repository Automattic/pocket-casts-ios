import Foundation

/// Control the presentation of the storieis
public class StoriesController {
    public static var shared = StoriesController()

    public enum Notifications: String, CaseIterable {
        case replay
        case share
    }

    private init() { }

    /// Start the stories from the beginning
    public func replay() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.replay.rawValue), object: nil)
    }

    public func share() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.share.rawValue), object: nil)
    }
}
