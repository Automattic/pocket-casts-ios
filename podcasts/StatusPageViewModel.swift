import SwiftUI
import PocketCastsUtils

class StatusPageViewModel: ObservableObject {
    @Published var running = false

    @Published var hasRun = false

    class Service: ObservableObject, Identifiable {
        let title: String
        let description: String
        let failureMessage: String
        let urls: [String]
        @Published var status: Result = .idle

        init(title: String, description: String, failureMessage: String, urls: [String] = []) {
            self.title = title
            self.description = description
            self.failureMessage = failureMessage
            self.urls = urls
        }

        enum Result {
            case success, failure, running, idle
        }
    }

    @Published var checks = [
        Service(
            title: L10n.settingsStatusInternet,
            description: L10n.settingsStatusInternetDescription,
            failureMessage: L10n.settingsStatusInternetFailureMessage
        ),
        Service(
            title: L10n.settingsStatusRefreshService,
            description: L10n.settingsStatusRefreshServiceDescription,
            failureMessage: L10n.settingsStatusServiceAdBlockerHelpSingular("refresh.pocketcasts.com"),
            urls: ["https://refresh.pocketcasts.com/health.html"]
        ),
        Service(
            title: L10n.settingsStatusAccountService,
            description: L10n.settingsStatusAccountServiceDescription,
            failureMessage: L10n.settingsStatusServiceAdBlockerHelpSingular("api.pocketcasts.com"),
            urls: ["https://api.pocketcasts.com/health"]
        ),
        Service(
            title: L10n.settingsStatusDiscover,
            description: L10n.settingsStatusDiscoverDescription,
            failureMessage: L10n.settingsStatusServiceAdBlockerHelpSingular("static.pocketcasts.com, cache.pocketcasts.com and podcasts.pocketcasts.com"),
            urls: ["https://static.pocketcasts.com/discover/android/content.json",
                   "https://cache.pocketcasts.com/mobile/podcast/full/e7a6f7d0-02f2-0133-1c51-059c869cc4eb"]
        )
    ]

    private lazy var networkUtils = NetworkUtils.shared

    @MainActor
    func run() {
        running = true

        Task {
            for service in checks {
                service.status = .running

                if networkUtils.isConnected() {
                    if service.urls.isEmpty {
                        service.status = .success
                    } else {
                        var responseCodes = [Int?]()

                        for url in service.urls {
                            if let url = URL(string: url) {
                                let status = await url.requestHTTPStatus()
                                responseCodes.append(status)
                            }
                        }

                        service.status = responseCodes.first(where: { $0 != 200 }) != nil ? .failure : .success
                    }
                } else {
                    service.status = .failure
                }
            }

            running = false
            hasRun = true
        }
    }
}

private extension URL {
    func requestHTTPStatus() async -> Int? {
        await withCheckedContinuation { continuation in
            var request = URLRequest(url: self)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let httpResponse = response as? HTTPURLResponse, error == nil {
                    continuation.resume(returning: httpResponse.statusCode)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            task.resume()
        }
    }
}
