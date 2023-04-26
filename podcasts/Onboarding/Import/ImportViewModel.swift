import Foundation
import SwiftUI

class ImportViewModel: OnboardingModel {
    var navigationController: UINavigationController?
    let availableSources: [ImportSource]

    var showSubtitle: Bool = true

    init() {
        self.availableSources = supportedSources.filter { $0.isSourceAvailable }
    }

    func didAppear() {
        OnboardingFlow.shared.track(.onboardingImportShown)
    }

    func didDismiss(type: OnboardingDismissType) {
        guard type == .swipe else { return }

        OnboardingFlow.shared.track(.onboardingImportDismissed)
    }

    @objc func dismissTapped() {
        OnboardingFlow.shared.track(.onboardingImportDismissed)
        navigationController?.dismiss(animated: true)
    }

    // MARK: - Import apps
    let supportedSources: [ImportSource] = [
        .init(id: .applePodcasts, displayName: "Apple Podcasts", steps: L10n.importInstructionsApplePodcastsSteps),
        .init(id: .breaker, displayName: "Breaker", steps: L10n.importInstructionsBreaker),
        .init(id: .castro, displayName: "Castro", steps: L10n.importInstructionsCastro),
        .init(id: .castbox, displayName: "Castbox", steps: L10n.importInstructionsCastbox),
        .init(id: .overcast, displayName: "Overcast", steps: L10n.importInstructionsOvercast),
        .init(id: .other, displayName: "other apps", steps: L10n.importPodcastsDescription),
        .init(id: .opmlFromURL, displayName: "URL", steps: L10n.importOpmlFromUrl)
    ]

    enum ImportSourceId: String, AnalyticsDescribable {
        case breaker, castbox = "wazecastbox", overcast, other, opmlFromURL
        case castro = "co.supertop.Castro-2"
        case applePodcasts = "https://pocketcasts.com/import-from-apple-podcasts"

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
            case .opmlFromURL:
                return "opml_from_url"
            }
        }
    }

    struct ImportSource: Identifiable, CustomDebugStringConvertible {
        let id: ImportSourceId
        let displayName: String
        let steps: String

        var isSourceAvailable: Bool {
            #if targetEnvironment(simulator)
            return true
            #endif

            // Always available - Others and opml from url are always available
            // Note: Even if Apple podcasts has been uninstalled by the user, the system will always report
            // that it's installed.
            if [.other, .applePodcasts, .opmlFromURL].contains(id) {
                return true
            }

            guard let url else {
                return false
            }

            return UIApplication.shared.canOpenURL(url)
        }

        var hideButton: Bool {
            switch id {
            case .other:
                return true
            default:
                return false
            }
        }

        func openApp() {
            guard let url else { return }

            UIApplication.shared.open(url)
        }

        private var url: URL? {
            if id == .other || id == .opmlFromURL { return nil }

            let string: String
            if id == .applePodcasts {
                string = id.rawValue
            } else {
                string = id.rawValue + "://"
            }

            return URL(string: string)
        }

        var debugDescription: String {
            return "\(displayName): \(isSourceAvailable ? "Yes" : "No")"
        }
    }
}


extension ImportViewModel {
    static func make(in navigationController: UINavigationController? = nil, source: String? = nil, showSubtitle: Bool = true) -> UIViewController {
        let viewModel = ImportViewModel()
        viewModel.showSubtitle = showSubtitle

        let controller = ImportHostingController(rootView: ImportLandingView(viewModel: viewModel).setupDefaultEnvironment())

        let navController = navigationController ?? UINavigationController(rootViewController: controller)
        viewModel.navigationController = navController
        controller.viewModel = viewModel

        if let source {
            OnboardingFlow.shared.updateAnalyticsSource(source)
        }
        return navigationController == nil ? navController : controller
    }
}

// MARK: - Landing View
extension ImportViewModel {
    func didSelect(_ importsource: ImportSource) {
        guard let navigationController else { return }
        OnboardingFlow.shared.track(.onboardingImportAppSelected, properties: ["app": importsource.id])

        let controller = UIHostingController(rootView: ImportDetailsView(importSource: importsource, viewModel: self).setupDefaultEnvironment())

        navigationController.pushViewController(controller, animated: true)
    }
}


// MARK: - Details
extension ImportViewModel {
    func openApp(_ app: ImportSource) {
        OnboardingFlow.shared.track(.onboardingImportOpenAppTapped, properties: ["app": app.id])

        app.openApp()
    }
}

// MARK: - OPML from URL
extension ImportViewModel {
    func importFromURL(_ url: URL, completion: @escaping ((Bool) -> Void)) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                print("Error downloading data: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
                return
            }

            let temporaryDirectory = FileManager.default.temporaryDirectory
            let fileURL = temporaryDirectory.appendingPathComponent("feed.opml")

            do {
                try data.write(to: fileURL)
                print("File downloaded to: \(fileURL)")
                self.importPodcastsFromOPML(url: fileURL)
            } catch {
                print("Error saving file: \(error.localizedDescription)")
                completion(false)
            }
        }

        task.resume()
    }

    func importPodcastsFromOPML(url: URL) {
        PodcastManager.shared.importPodcastsFromOpml(url)
    }
}
