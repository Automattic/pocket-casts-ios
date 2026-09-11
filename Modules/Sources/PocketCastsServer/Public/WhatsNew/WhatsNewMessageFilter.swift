import Foundation
import PocketCastsUtils

/// Decides which of the catalog's messages a user is meant to see.
///
/// The CDN publishes one catalog per platform and locale, so every remaining rule — who a message
/// is for, which builds can render it, when it's live, and whether it predates the account reading
/// it — travels on the message itself. Anything reading the feed has to apply the same rules,
/// whether it's drawing the list or only deriving the unread dot, or a message could be counted
/// unread on the Profile row and then be nowhere to be found in the feed it sends the user to.
public struct WhatsNewMessageFilter {
    /// The tier the account is on, which a message's audiences are matched against.
    public let audience: WhatsNewAudience

    /// The build the user is on, which a message's minimum app version is matched against, or `nil`
    /// when it isn't a version this can make sense of.
    public let appVersion: Version?

    /// The account the feed is being drawn for, which decides how far back it reaches.
    public let account: Account

    /// What the app knows about the account reading the feed.
    public enum Account: Hashable {
        /// Nobody is signed in, so there's no account for a message to have been published before.
        case signedOut

        /// Somebody is signed in, and this is when their account was created — `nil` while the app
        /// hasn't been told yet.
        case signedIn(createdAt: Date?)
    }

    public init(audience: WhatsNewAudience, appVersion: Version?, account: Account = .signedOut) {
        self.audience = audience
        self.appVersion = appVersion
        self.account = account
    }

    /// The filter for the account signed in and the build it's running on.
    public static var current: WhatsNewMessageFilter {
        let appVersion = ServerConfig.shared.syncDelegate?.appVersion() ?? ""
        return WhatsNewMessageFilter(audience: .current, appVersion: Version(appVersion), account: .current)
    }

    /// Whether the message clears every rule it carries.
    public func includes(_ message: WhatsNewMessage, at date: Date = Date()) -> Bool {
        postDatesTheAccount(message) && message.targeting.targets(audience) && isSupported(message) && isLive(message, at: date)
    }

    /// Whether the message was published after the account reading it was created.
    ///
    /// Someone who signed up last week has no use for a year of announcements about things that
    /// were already there when they arrived. Being signed in without knowing when that was hides
    /// the feed until the account's metadata has been fetched, rather than guessing at it.
    private func postDatesTheAccount(_ message: WhatsNewMessage) -> Bool {
        switch account {
        case .signedOut:
            return true
        case .signedIn(let createdAt):
            guard let createdAt else { return false }
            return message.publishedAt >= createdAt
        }
    }

    /// Whether the build is new enough for the message.
    ///
    /// A message with no minimum is for every build. A minimum that isn't a version, or a version
    /// we can't tell what we're running against, hides the message: a message gated on a build is
    /// usually pointing at something only that build has, so guessing is worse than staying quiet.
    private func isSupported(_ message: WhatsNewMessage) -> Bool {
        guard let minimumAppVersion = message.targeting.minimumAppVersion else { return true }
        guard let appVersion, let minimum = Version(minimumAppVersion) else { return false }
        return appVersion >= minimum
    }

    /// Whether the message is published and hasn't expired.
    ///
    /// The server leaves unpublished and expired messages out of the catalog it generates, but a
    /// cached catalog can outlive one of its messages, so the dates are worth checking here too.
    private func isLive(_ message: WhatsNewMessage, at date: Date) -> Bool {
        guard message.publishedAt <= date else { return false }
        guard let expiresAt = message.expiresAt else { return true }
        return expiresAt > date
    }
}

public extension WhatsNewMessageFilter.Account {
    /// The account the app is signed into, if it's signed into one.
    static var current: Self {
        guard SyncManager.isUserLoggedIn() else { return .signedOut }
        return .signedIn(createdAt: SubscriptionHelper.accountCreatedDate())
    }
}

public extension WhatsNewAudience {
    /// The audience the account currently falls into.
    static var current: WhatsNewAudience {
        switch SubscriptionHelper.activeTier {
        case .plus: .plus
        case .patron: .patron
        case .none: .free
        }
    }
}

private extension SubscriptionHelper {
    /// When the account was created, or `nil` when the app hasn't been told yet.
    ///
    /// `/subscription/status` carries the date the account was created rather than the date it
    /// subscribed, which is the same field the other clients hide pre-account messages by.
    /// `subscriptionCreateDate()` answers with the epoch when nothing has been stored for it.
    static func accountCreatedDate() -> Date? {
        guard let date = subscriptionCreateDate(), date.timeIntervalSince1970 > 0 else { return nil }
        return date
    }
}
