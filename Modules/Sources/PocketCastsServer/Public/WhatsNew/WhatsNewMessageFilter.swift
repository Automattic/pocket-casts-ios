import Foundation
import PocketCastsUtils

/// Decides which of the catalog's messages a user is meant to see.
///
/// The CDN publishes one catalog per platform and locale, so every remaining rule — who a message
/// is for, which builds can render it, and when it's live — travels on the message itself. Anything
/// reading the feed has to apply the same rules, whether it's drawing the list or only deriving the
/// unread dot, or a message could be counted unread on the Profile row and then be nowhere to be
/// found in the feed it sends the user to.
public struct WhatsNewMessageFilter {
    /// The tier the account is on, which a message's audiences are matched against.
    public let audience: WhatsNewAudience

    /// The build the user is on, which a message's minimum app version is matched against, or `nil`
    /// when it isn't a version this can make sense of.
    public let appVersion: Version?

    public init(audience: WhatsNewAudience, appVersion: Version?) {
        self.audience = audience
        self.appVersion = appVersion
    }

    /// The filter for the account signed in and the build it's running on.
    public static var current: WhatsNewMessageFilter {
        let appVersion = ServerConfig.shared.syncDelegate?.appVersion() ?? ""
        return WhatsNewMessageFilter(audience: .current, appVersion: Version(appVersion))
    }

    /// Whether the message clears every rule it carries.
    public func includes(_ message: WhatsNewMessage, at date: Date = Date()) -> Bool {
        message.targeting.targets(audience) && isSupported(message) && isLive(message, at: date)
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
