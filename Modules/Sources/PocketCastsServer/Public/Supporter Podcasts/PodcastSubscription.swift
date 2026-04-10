import Foundation
import PocketCastsUtils

public struct PodcastSubscription: Codable {
    public var uuid: String // userUuid
    public var masterUuid: String
    public var bundleUuid: String
    public var frequency: Int
    public var expiryDate: TimeInterval
    public var autoRenewing: Bool
    public var isPlusActivator: Bool = false
    public var platform: Int

    public func platformIsWeb() -> Bool {
        platform == SubscriptionPlatform.web.rawValue
    }

    public func isExpired() -> Bool {
        Date(timeIntervalSince1970: expiryDate).timeIntervalSinceNow < 0
    }
}
