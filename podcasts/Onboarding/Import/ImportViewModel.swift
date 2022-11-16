import Foundation
import SwiftUI

class ImportViewModel {
    var navigationController: UINavigationController?
    let installedApps: [ImportApp]

    init() {
        self.installedApps = supportedApps.filter { $0.isInstalled }
    }

    // MARK: - Import apps
    private let supportedApps: [ImportApp] = [
        .init(id: .applePodcasts, displayName: "Apple Podcasts", steps: L10n.importInstructionsApplePodcastsSteps),
        .init(id: .breaker, displayName: "Breaker", steps: L10n.importInstructionsBreaker),
        .init(id: .castro, displayName: "Castro", steps: L10n.importInstructionsCastro),
        .init(id: .castbox, displayName: "Castbox", steps: L10n.importInstructionsCastbox),
        .init(id: .overcast, displayName: "Overcast", steps: L10n.importInstructionsOvercast),
        .init(id: .other, displayName: "other apps", steps: L10n.importPodcastsDescription),
    ]

    enum ImportAppId: String {
        case breaker, castbox, overcast, other
        case castro = "co.supertop.Castro-2"
        case applePodcasts = "https://www.icloud.com/shortcuts/d420ce94cc964e3881e7808bc5ce773a"
    }

    struct ImportApp: Identifiable, CustomDebugStringConvertible {
        let id: ImportAppId
        let displayName: String
        let steps: String

        var isInstalled: Bool {
            // Always installed
            if id == .other {
                return true
            }

            guard let url else {
                return false
            }

            return UIApplication.shared.canOpenURL(url)
        }

        func openApp() {
            guard let url else { return }

            UIApplication.shared.open(url)
        }

        private var url: URL? {
            if id == .other { return nil }

            let string: String
            if id == .applePodcasts {
                string = "https://www.icloud.com/shortcuts/d9e0793e40ed4b5d9dd78c81e6af9234"
            } else {
                string = id.rawValue + "://app"
            }

            return URL(string: string)
        }

        var debugDescription: String {
            return "\(displayName): \(isInstalled ? "Yes" : "No")"
        }
    }
}

// MARK: - Landing View
extension ImportViewModel {
    func didSelect(_ app: ImportApp) {
        guard let navigationController else { return }
        let controller = UIHostingController(rootView: ImportDetailsView(app: app, viewModel: self).setupDefaultEnvironment())

        navigationController.pushViewController(controller, animated: true)
    }
}


// MARK: - Details
extension ImportViewModel {
    func openApp(_ app: ImportApp) {
        app.openApp()
    }
}
