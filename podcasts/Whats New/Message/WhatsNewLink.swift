import Foundation
import JLRoutes
import UIKit

/// Somewhere a What's New action block is allowed to send the user.
///
/// The catalog is public, declarative content rather than a format the app executes, so an action's
/// URL has to resolve to one of the two kinds of link the app implements. Anything else — another
/// app's scheme, a plain `http` page, a `mailto:` — is dropped instead of handed to the system.
enum WhatsNewLink: Hashable {
    /// A destination inside the app, routed the same way as any other Pocket Casts deep link.
    case deepLink(URL)

    /// A web page, opened in an in-app Safari view.
    case web(URL)

    /// The scheme the app registers.
    private static let appScheme = "pktc"

    /// The scheme the shared What's New contract writes in-app links with.
    ///
    /// The catalog is authored once for every client, so iOS answers to it as well as to its own.
    private static let contractScheme = "pocketcasts"

    init?(url: URL) {
        guard let scheme = url.scheme?.lowercased() else { return nil }

        switch scheme {
        case Self.appScheme:
            self = .deepLink(url)
        case Self.contractScheme:
            guard let url = url.replacingScheme(with: Self.appScheme) else { return nil }
            self = .deepLink(url)
        case "https":
            self = .web(url)
        default:
            return nil
        }
    }

    @MainActor
    func open() {
        switch self {
        case .deepLink(let url):
            JLRoutes.routeURL(url)
        case .web(let url):
            UIApplication.shared.openSafariVCIfPossible(url)
        }
    }
}

private extension URL {
    func replacingScheme(with scheme: String) -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }
        components.scheme = scheme
        return components.url
    }
}
