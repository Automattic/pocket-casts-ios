import Foundation
import PocketCastsDataModel
import PocketCastsServer

class OpmlImporter: Operation, XMLParserDelegate {
    private var podcastsToAdd = [String]()
    private var pollUuids = [String]()
    private var failedCount = 0

    private let opmlFileUrl: URL
    private let progressWindow: ShiftyLoadingAlert

    private var initialPodcastCount = 0
    private var importedCount = 0

    lazy var importQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 5

        return queue
    }()

    private var parsedUrls = [String]()

    init(opmlFile: URL, progressWindow: ShiftyLoadingAlert) {
        opmlFileUrl = opmlFile
        self.progressWindow = progressWindow

        super.init()
    }

    override func main() {
        autoreleasepool {
            // parse OPML file
            let parser = XMLParser(contentsOf: opmlFileUrl)
            parser?.delegate = self
            guard let parsed = parser?.parse(), parsed, parsedUrls.count > 0 else {
                DispatchQueue.main.sync {
                    self.progressWindow.hideAlert(false)
                    let controller = SceneHelper.rootViewController()

                    SJUIUtils.showAlert(title: L10n.opmlImportFailedTitle, message: L10n.opmlImportFailedMessage, from: controller)
                }

                return
            }

            // send urls to server 100 at a time
            initialPodcastCount = parsedUrls.count
            importPodcasts(uuids: parsedUrls)

            var amountOfTimesPolled = 0
            while amountOfTimesPolled < 20, pollUuids.count > 0 {
                amountOfTimesPolled += 1

                let pollUuidsToSend = pollUuids
                pollUuids.removeAll()
                importPodcasts(uuids: pollUuidsToSend)
                Thread.sleep(forTimeInterval: TimeInterval(amountOfTimesPolled))
            }

            DispatchQueue.main.async {
                NavigationManager.sharedManager.navigateTo(NavigationManager.podcastListPageKey, data: nil)

                self.progressWindow.hideAlert(true)

                NotificationCenter.postOnMainThread(notification: Constants.Notifications.opmlImportCompleted)
            }
        }
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        guard elementName.lowercased() == "outline", let url = attributeDict["xmlUrl"] else { return }

        parsedUrls.append(url)
    }

    private func importPodcasts(uuids: [String]) {
        let serverCallDispathGroup = DispatchGroup()
        uuids.chunked(into: 100).forEach { chunk in
            serverCallDispathGroup.enter()

            MainServerHandler.shared.sendOpmlChunk(feedUrls: chunk) { response in
                guard let uploadResponse = response, uploadResponse.success() else {
                    // since there might be multiple chunks, if this one fails, just go to the next one
                    serverCallDispathGroup.leave()
                    return
                }

                // since the code below is going to be making more network requests, get this call off the URLSession delegate queue
                DispatchQueue.global().async {
                    if let result = uploadResponse.result {
                        self.podcastsToAdd = result.uuids ?? []
                        self.pollUuids += result.pollUuids ?? []
                        self.failedCount += result.failedCount

                        self.addAllPendingPodcasts()
                        self.podcastsToAdd.removeAll()
                    }
                    serverCallDispathGroup.leave()
                }
            }

            _ = serverCallDispathGroup.wait(timeout: .now() + 2.minutes)
        }
    }

    // MARK: - Add Podcasts

    private func addAllPendingPodcasts() {
        for uuid in podcastsToAdd {
            importQueue.addOperation {
                // check to see if we already have this podcast
                let existingPodcast = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true)
                if let podcast = existingPodcast {
                    if !podcast.isSubscribed() {
                        podcast.subscribed = 1
                        podcast.syncStatus = SyncStatus.notSynced.rawValue
                        DataManager.sharedManager.save(podcast: podcast)
                    }
                    self.importedCount += 1
                    DispatchQueue.main.async {
                        self.progressWindow.title = self.progress(imported: self.importedCount, total: self.initialPodcastCount)
                    }

                    return
                }

                // if we get here we don't have this podcast, so we need to add it
                let addGroup = DispatchGroup()
                addGroup.enter()
                ServerPodcastManager.shared.addFromUuid(podcastUuid: uuid, subscribe: true) { _ in
                    self.importedCount += 1

                    DispatchQueue.main.async {
                        self.progressWindow.title = self.progress(imported: self.importedCount, total: self.initialPodcastCount)
                    }

                    addGroup.leave()
                }

                // wait for the add operation to return
                _ = addGroup.wait(timeout: .now() + 30.seconds)
            }
        }

        importQueue.waitUntilAllOperationsAreFinished()
    }

    func progress(imported: Int, total: Int) -> String {
        L10n.opmlImportProgressFormat(imported.localized(), total.localized())
    }
}
