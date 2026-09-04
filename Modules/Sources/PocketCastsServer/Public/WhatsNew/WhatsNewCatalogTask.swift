import Foundation
import PocketCastsUtils

/// Fetches the What's New catalog published to the CDN, caching the last good copy on disk.
public struct WhatsNewCatalogTask {
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

    /// The language the catalog is requested for, such as `en`.
    public static var currentLocale: String {
        Locale.current.language.languageCode?.identifier ?? fallbackLocale
    }

    /// The catalog for the current locale, refreshed from the CDN.
    ///
    /// Falls back to the cached catalog when the request fails or returns something that can't be
    /// decoded, and only rethrows when the refresh was cancelled or there's nothing cached to fall
    /// back to.
    public func catalog() async throws -> WhatsNewCatalog {
        do {
            return try await refresh()
        } catch {
            guard !error.isCancellation, let cached = cachedCatalog() else { throw error }
            FileLog.shared.addMessage("What's New: catalog request failed: \(error.localizedDescription). Returning the cached catalog")
            return cached
        }
    }

    /// The last catalog that was fetched successfully, read back from disk.
    public func cachedCatalog() -> WhatsNewCatalog? {
        guard let data = cache.data(forLocale: locale) else { return nil }
        return try? WhatsNewCatalog.decoder.decode(WhatsNewCatalog.self, from: data)
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

private extension Error {
    var isCancellation: Bool {
        self is CancellationError || (self as? URLError)?.code == .cancelled
    }
}
