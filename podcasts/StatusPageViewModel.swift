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
                        for url in service.urls {
                            if let url = URL(string: url) {
                                let status = await url.requestHTTPStatus()
                                service.status = status == 200 ? .success : .failure
                            }
                        }
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
            request.httpMethod = "HEAD"
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
