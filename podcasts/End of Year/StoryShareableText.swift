import UIKit
import PocketCastsServer
import PocketCastsDataModel

class StoryShareableText: UIActivityItemProvider {
    private var text: String

    private let hashtags = "#pocketcasts #endofyear2022"
    private let pocketCastsUrl = "https://pca.st/"

    private var shortenedURL: String?
    private var longURL: String?
    private var podcastListURL: String?

    init(_ text: String) {
        self.text = text
        super.init(placeholderItem: self.text)
    }

    init(_ text: String, podcast: Podcast) {
        self.text = text
        super.init(placeholderItem: self.text)
        self.longURL = podcast.shareURL
        requestShortenedURL()
    }

    init(_ text: String, episode: Episode) {
        self.text = text
        super.init(placeholderItem: self.text)
        self.longURL = episode.shareURL
        requestShortenedURL()
    }

    init(_ text: String, podcasts: [Podcast]) {
        self.text = text
        super.init(placeholderItem: self.text)
        podcastListURL = ""
        createList(from: podcasts)
    }

    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        // Facebook ignores text, so we only share the image
        // WhatsApp ignore the image if we share text, so we also share just the image
        if activityType == .postToFacebook ||
            activityType?.rawValue.contains("whatsapp") == true {
            return nil
        }

        var text = self.text

        // For Messages we don't want to add hashtags
        if activityType != .message {
            text = "\(text) \(hashtags)".trim()
        }

        if let longURL {
            return String(format: text, shortenedURL ?? longURL)
        }

        if let podcastListURL {
            return String(format: text, podcastListURL)
        }

        return "\(text) \(pocketCastsUrl)"
    }

    private func requestShortenedURL() {
        guard let longURL, let url = URL(string: longURL) else {
            return
        }

        let task = URLSession(configuration: .default, delegate: self, delegateQueue: nil).dataTask(with: url) { _, _, _ in }

        task.resume()
    }

    private func createList(from podcasts: [Podcast]) {
        if let shareUrl = Settings.top5PodcastsListLink {
            podcastListURL = shareUrl
            return
        }

        let listInfo = SharingServerHandler.PodcastShareInfo(title: L10n.eoyStoryTopPodcastsListTitle, description: "", podcasts: podcasts.map { $0.uuid })
        SharingServerHandler.shared.sharePodcastList(listInfo: listInfo) { [weak self] shareUrl in
            DispatchQueue.main.async {
                if let shareUrl = shareUrl {
                    Settings.top5PodcastsListLink = shareUrl
                    self?.podcastListURL = shareUrl
                }
            }
        }
    }
}

extension StoryShareableText: URLSessionDelegate, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        // Stops the redirection, and returns (internally) the response body.
        completionHandler(nil)
        if let url = request.url?.absoluteString {
            shortenedURL = url
        }
    }
}
