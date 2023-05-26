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
        Service(title: "Internet", description: "Check the status of your network.", failureMessage: "Unable to connect to the internet. Try connecting on a different network (e.g. mobile data).")
    ]

    private lazy var networkUtils = NetworkUtils.shared

    func run() {
        running = true

        checks.forEach { service in
            if networkUtils.isConnected() {
                if service.urls.isEmpty {
                    service.status = .success
                } else {
                    // Check URLs
                }
            } else {
                service.status = .failure
            }
        }

        running = false
        hasRun = true
    }
}
