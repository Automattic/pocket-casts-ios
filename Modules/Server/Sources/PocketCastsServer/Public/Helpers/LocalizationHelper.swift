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
    public let allowedHosts: Set<String>

    public init(userRegion: String?, appLanguage: String? = nil, allowedHosts: Set<String>? = nil) {
        self.userRegion = userRegion
        self.appLanguage = appLanguage ?? Self.defaultAppLanguage()
        self.allowedHosts = allowedHosts ?? Self.defaultAllowedHosts()
    }

    static func defaultAppLanguage() -> String {
        return Locale.preferredLanguages.first ?? Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
    }

    static func defaultAllowedHosts() -> Set<String> {
        return [
            ServerConstants.Urls.main(),
            ServerConstants.Urls.api(),
            ServerConstants.Urls.cache(),
            ServerConstants.Urls.sharing(),
            ServerConstants.Urls.discover(),
            ServerConstants.Urls.image(),
            ServerConstants.Urls.files(),
            ServerConstants.Urls.share(),
            ServerConstants.Urls.lists(),
            ServerConstants.Urls.search
        ]
            .compactMap { URL(string: $0)?.host }
            .reduce(into: Set<String>()) { $0.insert($1) }
    }
}
