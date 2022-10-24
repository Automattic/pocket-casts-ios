import Foundation

/// Control the presentation of the stories
class StoriesController {
    static var shared = StoriesController()

    enum Notifications: String, CaseIterable {
        case replay
    }

    private init() { }

    /// Start the stories from the beginning
    func replay() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.replay.rawValue), object: nil)
    }
}
