import Foundation

public class LocalizationHelper {
    public static var provider: InternationalizationProvider?

    public static func update(userRegion: String) {
        provider = InternationalizationProvider(userRegion: userRegion)
    }
}

public struct InternationalizationProvider {
    public let userRegion: String?
    public let appLanguage: String

    public init(userRegion: String?, appLanguage: String? = nil) {
        self.userRegion = userRegion
        self.appLanguage = appLanguage ?? Self.defaultAppLanguage()
    }

    static func defaultAppLanguage() -> String {
        return Locale.preferredLanguages.first ?? Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
    }
}

