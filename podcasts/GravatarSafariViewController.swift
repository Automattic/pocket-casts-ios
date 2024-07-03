import UIKit
import SafariServices

final class GravatarSafariViewController: SFSafariViewController {

    enum Destination {
        case avatarUpdate(email: String)

        var url: URL? {
            switch self {
            case .avatarUpdate(let email):
                guard var components = URLComponents(string: "https://gravatar.com/profile") else { return nil }
                components.queryItems = [
                    .init(name: "is_quick_editor", value: "true"),
                    .init(name: "email", value: email),
                    .init(name: "scope", value: "avatars")
                ]
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
