import UIKit
import SafariServices

final class GravatarSafariViewController: SFSafariViewController {

    enum Destination {
        case avatarUpdate(email: String)

        var url: URL? {
            switch self {
            case .avatarUpdate(let email):
                return URL(string: "https://gravatar.com/profile/avatars")
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
       // Toast.show(L10n.grav)
    }
}
