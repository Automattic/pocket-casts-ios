import Foundation
import PocketCastsUtils

/// Fetches the What's New catalog published to the CDN, caching the last good copy on disk.
public struct WhatsNewCatalogTask: Sendable {
    public enum WhatsNewCatalogError: Error {
        case requestFailed(statusCode: Int)
    }

    private let session: URLSession
    private let cache: WhatsNewCatalogCache
    private let locale: String

    public init(session: URLSession = .shared,
                cache: WhatsNewCatalogCache = WhatsNewCatalogCache(),
                locale: String = WhatsNewCatalogTask.currentLocale) {
        self.session = session
        self.cache = cache
        self.locale = locale
    }

    /// The language the catalog falls back to when the CDN doesn't publish the current one.
    public static let fallbackLocale = "en"

    /// The catalogs published under a region rather than under a bare language.
    ///
    /// Every other catalog is named after its language, so only the exceptions are worth listing:
    /// a language the feed picks up later needs nothing here, and the CDN answering with a 404 is
    /// what covers one it hasn't picked up yet.
    private static let regionalLocales: Set<String> = ["pt-br", "zh-cn", "zh-tw"]

    /// The catalog the app asks for, such as `en` or `pt-br`.
    public static var currentLocale: String {
        locale(forLocalization: Bundle.main.preferredLocalizations.first ?? fallbackLocale)
    }

    /// The catalog named after one of the app's own localizations, such as `pt-BR`.
    ///
    /// The catalog names its Chinese variants by region where the app names them by script, and
    /// names everything else by language, so a localization keeps its region only where the feed
    /// publishes one: `es-MX` reads the Spanish catalog, `pt-BR` its own.
    static func locale(forLocalization localization: String) -> String {
        let identifier = localization.lowercased().replacingOccurrences(of: "_", with: "-")
        if identifier.hasPrefix("zh-hans") { return "zh-cn" }
        if identifier.hasPrefix("zh-hant") { return "zh-tw" }
        if regionalLocales.contains(identifier) { return identifier }

        return String(identifier.prefix { $0 != "-" })
    }

    /// The last catalog that was fetched successfully, read back from disk.
    public func cachedCatalog() -> WhatsNewCatalog? {
        guard let data = cache.data(forLocale: locale) else { return nil }
        return try? WhatsNewCatalog.decoder.decode(WhatsNewCatalog.self, from: data)
    }

    /// When the catalog on disk was last written, or `nil` when nothing has been cached yet.
    public var cachedCatalogDate: Date? {
        cache.modificationDate(forLocale: locale)
    }

    /// Fetches the catalog from the CDN, replacing the cached copy once it decodes.
    ///
    /// Requests the current language and falls back to `en` when the CDN doesn't publish it, so a
    /// device set to a language the feed hasn't been translated into still sees the messages.
    public func refresh() async throws -> WhatsNewCatalog {
        let data: Data
        do {
            data = try await fetchData(forLocale: locale)
        } catch WhatsNewCatalogError.requestFailed(let statusCode)
                    where statusCode == ServerConstants.HttpConstants.notFound && locale != Self.fallbackLocale {
            FileLog.shared.addMessage("What's New: no catalog published for \(locale). Falling back to \(Self.fallbackLocale)")
            data = try await fetchData(forLocale: Self.fallbackLocale)
        }

        let catalog = try WhatsNewCatalog.decoder.decode(WhatsNewCatalog.self, from: data)
        cache.save(data, forLocale: locale)
        return catalog
    }

    private func fetchData(forLocale locale: String) async throws -> Data {
        let url = try URL(throwing: ServerConstants.Urls.whatsNew() + "\(locale).json")
        var request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 30.seconds)
        request.addLocalizationHeaders()

        let (data, response) = try await session.data(for: request)

        let statusCode = response.extractStatusCode()
        guard statusCode == ServerConstants.HttpConstants.ok else {
            throw WhatsNewCatalogError.requestFailed(statusCode: statusCode)
        }
        return data
    }
}
