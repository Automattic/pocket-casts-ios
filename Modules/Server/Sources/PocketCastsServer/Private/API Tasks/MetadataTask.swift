import Foundation
import PocketCastsDataModel
import PocketCastsUtils

class MetadataTask: Operation {
    static let minBytesInFile = 150 * 1024 as Int64

    var episodeUuid = ""

    private lazy var dispatchGroup: DispatchGroup = {
        let dispatchGroup = DispatchGroup()

        return dispatchGroup
    }()

    override func main() {
        autoreleasepool {
            downloadMetadata()
        }
    }

    private func downloadMetadata() {
        guard let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid), let downloadUrl = episode.downloadUrl, let url = URL(string: downloadUrl) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 20.seconds
        request.setValue(ServerConstants.Values.appUserAgent, forHTTPHeaderField: ServerConstants.HttpHeaders.userAgent)

        dispatchGroup.enter()
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            guard let strongSelf = self, let httpResponse = response as? HTTPURLResponse, error == nil else {
                self?.dispatchGroup.leave()

                return
            }

            MetadataTask.updateEpisodeFrom(response: httpResponse, episode: episode)
            strongSelf.dispatchGroup.leave()
        }
        task.resume()

        _ = dispatchGroup.wait(timeout: .now() + 30.seconds)
    }

    class func updateEpisodeFrom(response: HTTPURLResponse, episode: Episode) {
        let responseHeaders = response.allHeaderFields
        if responseHeaders.count == 0 { return } // no response headers

        var performedUpdate = false
        if let contentType = responseHeaders[ServerConstants.HttpHeaders.contentType] as? String, contentType.count > 0 {
            // if we don't have a content type, or the server said this is a video, change our file type
            if (episode.fileType ?? "").isEmpty || contentType.hasPrefix("video") {
                DataManager.sharedManager.saveEpisode(fileType: contentType, episode: episode)
                performedUpdate = true
            }
        }

        if let contentLength = responseHeaders["Content-Length"] as? String, let intLength = Int64(contentLength), intLength > MetadataTask.minBytesInFile, episode.sizeInBytes != intLength {
            DataManager.sharedManager.saveEpisode(fileSize: intLength, episode: episode)
            performedUpdate = true
        }

        if performedUpdate {
            NotificationCenter.default.post(name: ServerNotifications.episodeTypeOrLengthChanged, object: episode.uuid)
        }
    }
}
