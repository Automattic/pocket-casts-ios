import Foundation
import PocketCastsUtils

/// Decides which of the catalog's messages a user is meant to see.
///
/// The CDN publishes one catalog per platform and locale, so every remaining rule — who a message
/// is for, which builds can render it, and when it's live — travels on the message itself, apart
/// from the kinds of message this build is configured not to show, like polls, and the news that was
/// already old when the app was installed. Anything reading the
/// feed has to apply the same rules, whether it's drawing the list or only deriving the
/// unread dot, or a message could be counted unread on the Profile row and then be nowhere to be
/// found in the feed it sends the user to.
public struct WhatsNewMessageFilter {
    /// The tier the account is on, which a message's audiences are matched against.
    public let audience: WhatsNewAudience

    /// The build the user is on, which a message's minimum app version is matched against, or `nil`
    /// when it isn't a version this can make sense of.
    public let appVersion: Version?

    /// Whether research messages, which ask the user to answer a poll, are shown.
    public let includesPolls: Bool

    /// When the app was installed, or `nil` for an install updated from a version that didn't record it.
    public let installDate: Date?

    public init(audience: WhatsNewAudience, appVersion: Version?, includesPolls: Bool = FeatureFlag.whatsNewPolls.enabled, installDate: Date? = nil) {
        self.audience = audience
        self.appVersion = appVersion
        self.includesPolls = includesPolls
        self.installDate = installDate
    }

    /// The filter for the account signed in and the build it's running on.
    public static var current: WhatsNewMessageFilter {
        let appVersion = ServerConfig.shared.syncDelegate?.appVersion() ?? ""
        return WhatsNewMessageFilter(audience: .current, appVersion: Version(appVersion), installDate: ServerSettings.appInstallDate())
    }

    /// Whether the message clears every rule it carries and is a kind this build shows.
    public func includes(_ message: WhatsNewMessage, at date: Date = Date()) -> Bool {
        (includesPolls || message.type != .research)
            && message.targeting.targets(audience)
            && isSupported(message)
            && isLive(message, at: date)
            && !predatesInstall(message)
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

    /// Whether the message is an announcement or a poll published before the app was installed.
    ///
    /// Those were news to whoever had the app at the time, and a new user has nothing to take from
    /// them, while a new feature, a tip, or a known issue published before the install is as useful to
    /// them as to anyone. A user updating from an earlier version was there for all of it.
    private func predatesInstall(_ message: WhatsNewMessage) -> Bool {
        guard let installDate, message.type == .announcement || message.type == .research else { return false }
        return message.publishedAt < installDate
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
