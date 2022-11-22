import Foundation
import SwiftUI

class ImportViewModel: OnboardingModel {
    var navigationController: UINavigationController?
    let installedApps: [ImportApp]

    init() {
        self.installedApps = supportedApps.filter { $0.isInstalled }
    }

    func didAppear() {
        Analytics.track(.onboardingImportShown)
    }

    func didDismiss(type: OnboardingDismissType) {
        guard type == .swipe else { return }

        Analytics.track(.onboardingImportDismissed)
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

    enum ImportAppId: String, AnalyticsDescribable {
        case breaker, castbox = "wazecastbox", overcast, other
        case castro = "co.supertop.Castro-2"
        case applePodcasts = "https://www.icloud.com/shortcuts/d9e0793e40ed4b5d9dd78c81e6af9234"

        var analyticsDescription: String {
            switch self {
            case .breaker:
                return "breaker"
            case .castbox:
                return "castbox"
            case .overcast:
                return "overcast"
            case .other:
                return "other"
            case .castro:
                return "castro"
            case .applePodcasts:
                return "apple_podcasts"
            }
        }
    }

    struct ImportApp: Identifiable, CustomDebugStringConvertible {
        let id: ImportAppId
        let displayName: String
        let steps: String

        var isInstalled: Bool {
            #if targetEnvironment(simulator)
            return true
            #endif

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
                string = id.rawValue
            } else {
                string = id.rawValue + "://"
            }

            return URL(string: string)
        }

        var debugDescription: String {
            return "\(displayName): \(isInstalled ? "Yes" : "No")"
        }
    }
}

extension ImportViewModel {
    static func make(in navigationController: UINavigationController? = nil) -> UIViewController {
        let viewModel = ImportViewModel()
        let controller = OnboardingHostingViewController(rootView: ImportLandingView(viewModel: viewModel).setupDefaultEnvironment())

        let navController = navigationController ?? UINavigationController(rootViewController: controller)
        viewModel.navigationController = navController
        controller.viewModel = viewModel

        return navigationController == nil ? navController : controller
    }
}

// MARK: - Landing View
extension ImportViewModel {
    func didSelect(_ app: ImportApp) {
        guard let navigationController else { return }
        Analytics.track(.onboardingImportAppSelected, properties: ["app": app.id])

        let controller = UIHostingController(rootView: ImportDetailsView(app: app, viewModel: self).setupDefaultEnvironment())

        navigationController.pushViewController(controller, animated: true)
    }
}


// MARK: - Details
extension ImportViewModel {
    func openApp(_ app: ImportApp) {
        Analytics.track(.onboardingImportOpenAppTapped, properties: ["app": app.id])

        app.openApp()
    }
}
