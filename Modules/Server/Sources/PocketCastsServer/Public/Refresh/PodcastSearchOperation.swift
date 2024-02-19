import Foundation

class PodcastSearchOperation: Operation {
    private let completion: (PodcastSearchResponse?) -> Void
    private let searchQuery: MainServerHandler.PodcastSearchQuery

    private lazy var dispatchGroup: DispatchGroup = {
        let dispatchGroup = DispatchGroup()

        return dispatchGroup
    }()

    init(searchQuery: MainServerHandler.PodcastSearchQuery, completionHandler: @escaping (PodcastSearchResponse?) -> Void) {
        completion = completionHandler
        self.searchQuery = searchQuery
        super.init()
    }

    // This method calls a pollable API that is defined as needing to be called like this by the server team:
    // call first time, if status == "poll"
    // Wait 2 seconds then call again
    // Wait 2 seconds then call
    // Wait 5 seconds then call
    // Wait 5 seconds then call
    // Wait 5 seconds then call
    // Wait 5 seconds then call
    // Wait 10 seconds then call
    // give up
    override func main() {
        autoreleasepool {
            var pollCount = 0
            while true {
                let shouldRetry = performSearch()
                if !shouldRetry { break }

                pollCount += 1
                let backOffTime = pollBackoffTime(pollCount: pollCount)
                if backOffTime < 0 {
                    completion(PodcastSearchResponse.failedResponse())
                    break
                }

                Thread.sleep(forTimeInterval: backOffTime)
            }
        }
    }

    private func performSearch() -> Bool {
        let url = ServerHelper.asUrl(ServerConstants.Urls.main() + "podcasts/search")
        guard let request = ServerHelper.createJsonRequest(url: url, params: searchQuery, timeout: 10, cachePolicy: .reloadIgnoringCacheData) else {
            completion(PodcastSearchResponse.failedResponse())

            return false
        }

        var shouldRetry = false
        dispatchGroup.enter()
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                shouldRetry = true
                self.completion(PodcastSearchResponse.failedResponse())
                self.dispatchGroup.leave()

                return
            }

            do {
                let searchResponse = try JSONDecoder().decode(PodcastSearchResponse.self, from: data)
                if searchResponse.status == "poll" {
                    shouldRetry = true
                } else {
                    shouldRetry = false
                    self.completion(searchResponse)
                }
            } catch {
                self.completion(PodcastSearchResponse.failedResponse())
            }

            self.dispatchGroup.leave()

        }.resume()
        _ = dispatchGroup.wait(timeout: .now() + 15.seconds)

        return shouldRetry
    }

    private func pollBackoffTime(pollCount: Int) -> TimeInterval {
        if pollCount < 3 {
            return 2
        }
        if pollCount < 7 {
            return 5
        }
        if pollCount == 7 {
            return 10
        }

        return -1
    }
}
