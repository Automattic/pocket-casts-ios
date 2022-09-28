import Foundation
import PocketCastsServer

class SharedItemImporter: Operation {
    private var urlToImport: String
    private var completion: (IncomingShareItem?) -> Void

    private lazy var dispatchGroup: DispatchGroup = {
        let dispatchGroup = DispatchGroup()

        return dispatchGroup
    }()

    init(strippedUrl: String, completion: @escaping (IncomingShareItem?) -> Void) {
        urlToImport = strippedUrl
        self.completion = completion
    }

    override func main() {
        autoreleasepool {
            dispatchGroup.enter()
            MainServerHandler.shared.lookupShareLink(sharePath: urlToImport) { [weak self] listResponse in
                guard let listResponse = listResponse, listResponse.success() else {
                    self?.sendResponse()
                    return
                }

                let incomingItem = IncomingShareItem()
                if let podcast = listResponse.result?.podcast {
                    incomingItem.podcastHeader = PodcastHeader(sharedPodcast: podcast)
                }
                incomingItem.fromTime = listResponse.result?.time
                if let episode = listResponse.result?.episode {
                    incomingItem.episodeHeader = EpisodeHeader(refreshEpisode: episode)
                }

                self?.sendResponse(item: incomingItem)
            }

            _ = dispatchGroup.wait(timeout: .now() + 30.seconds)
        }
    }

    private func sendResponse(item: IncomingShareItem? = nil) {
        DispatchQueue.main.sync { [weak self] in
            self?.completion(item)
        }
        dispatchGroup.leave()
    }
}
