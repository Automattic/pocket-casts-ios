import UIKit
import PocketCastsServer
import PocketCastsDataModel

class StoryShareableText: UIActivityItemProvider, ShareableMetadataDataSource {
    private var text: String

    private let pocketCastsUrl = ServerConstants.Urls.share()

    private var shortenedURL: String?
    private var longURL: String?
    private var podcastListURL: String?

    var shareableMetadataProvider = ShareableMetadataProvider()

    var hashtags: [String] {
        ["pocketcasts", "playback2023"]
    }

    var shareableLink: String {
        return [shortenedURL, longURL, podcastListURL].compactMap { $0 }.first ?? pocketCastsUrl
    }

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
        shareableMetadataProvider.dataSource = self

        // Facebook ignores text, so we only share the image
        // WhatsApp ignore the image if we share text, so we also share just the image
        if activityType == .postToFacebook ||
            activityType?.rawValue.contains("whatsapp") == true {
            return nil
        }

        let supportsMetadata = activityType?.supportsShareableMetadata ?? false
        let showHashTags = activityType != .message && !supportsMetadata

        let text = shareableText(showLinks: !supportsMetadata, showHashTags: showHashTags).trim()

        // Remove any empty text to prevent gaps
        guard !text.isEmpty else { return nil }
        guard supportsMetadata else { return text }

        // Show the text as a title when sharing to a metadata network such as Tumblr
        let item = NSExtensionItem()
        item.attributedTitle = NSAttributedString(string: text)
        return item
    }

    private func shareableText(showLinks: Bool, showHashTags: Bool) -> String {
        var text = self.text

        // For Messages we don't want to add hashtags
        if showHashTags {
            let tags = hashtags.map { "#" + $0 }.joined(separator: " ")
            text = "\(text) \(tags)".trim()
        }

        if let longURL {
            let url = showLinks ? (shortenedURL ?? longURL) : ""
            return String(format: text, url)
        }

        if let podcastListURL {
            return String(format: text, showLinks ? podcastListURL : "")
        }

        return "\(text)" + (showLinks ? " \(pocketCastsUrl)" : "")
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
