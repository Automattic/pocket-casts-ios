import UIKit
import SafariServices

final class GravatarSafariViewController: SFSafariViewController {

    enum Destination {
        case avatarUpdate(email: String)

        var url: URL? {
            switch self {
            case .avatarUpdate(let email):
                guard var components = URLComponents(string: "https://gravatar.com/profile") else { return nil }
                components.percentEncodedQueryItems = [
                    URLQueryItem(name: "is_quick_editor", value: "true"),
                    URLQueryItem(name: "email", value: email),
                    URLQueryItem(name: "scope", value: "avatars")
                ].map({ $0.percentEncoded() })
                return components.url
            }
        }
    }

    init?(destination: Destination) {
        guard let url = destination.url else { return nil }
        super.init(url: url, configuration: .appDefault)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: Constants.Notifications.avatarNeedsRefreshing, object: nil)
    }
}

fileprivate extension URLQueryItem {
    func percentEncoded() -> URLQueryItem {
        /// addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) encode parameters following RFC 3986
        /// According to RFC 3986, `+` is a valid character so it is not encoded.
        /// We should encode "+" sign with its HTTP equivalent.

        var newQueryItem = self
        newQueryItem.value = value?
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .replacingOccurrences(of: "+", with: "%2B")

        return newQueryItem
    }
}
