import Foundation
import Combine
import PocketCastsServer
import PocketCastsDataModel

/// Represents a view that will display information about the users profile such as email, subscription status, and stats
class ProfileDataViewModel: ObservableObject {

    // Allow UIKit to update to view size changes
    private(set) var contentSize: CGSize? = nil
    var viewContentSizeChanged: (() -> Void)? = nil

    /// The user profile information such as logged in, email, etc
    var profile: UserInfo.Profile = .init()

    /// The users subscription information, will be nil if there is no active subscription
    var subscription: UserInfo.Subscription?

    /// Listening Stats
    var stats: UserInfo.Stats = .init()

    private var notifications = Set<AnyCancellable>()

    init() {
        update()

        // Listen for the refresh event to update the view
        NotificationCenter.default
            .publisher(for: ServerNotifications.podcastsRefreshed)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in self?.update() })
            .store(in: &notifications)
    }

    /// Refresh the store data
    func update() {
        profile = .init()
        subscription = .init(loggedIn: profile.isLoggedIn)
        stats = .init()

        objectWillChange.send()
    }

    func contentSizeChanged(_ size: CGSize) {
        contentSize = size
        viewContentSizeChanged?()
    }
}
