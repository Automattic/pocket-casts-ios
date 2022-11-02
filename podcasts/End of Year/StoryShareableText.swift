import UIKit
import PocketCastsDataModel

class StoryShareableText: UIActivityItemProvider {
    private var text: String

    private let hashtags = "#pocketcasts #endofyear2022"
    private let pocketCastsUrl = "https://pca.st/"

    private var shortenedURL: String?
    private var longURL: String?

    init(_ text: String) {
        self.text = "\(text) \(hashtags) \(pocketCastsUrl)"
        super.init(placeholderItem: self.text)
    }

    init(_ text: String, podcast: Podcast) {
        self.text = "\(text) \(hashtags)"
        super.init(placeholderItem: self.text)
        self.longURL = podcast.shareURL
        requestShortenedURL()
    }

    init(_ text: String, episode: Episode) {
        self.text = "\(text) \(hashtags)"
        super.init(placeholderItem: self.text)
        self.longURL = episode.shareURL
        requestShortenedURL()
    }

    override var item: Any {
        if let longURL {
            return String(format: text, shortenedURL ?? longURL)
        }

        return text
    }

    private func requestShortenedURL() {
        guard let longURL, let url = URL(string: longURL) else {
            return
        }

        let task = URLSession(configuration: .default, delegate: self, delegateQueue: nil).dataTask(with: url) { _, _, _ in }

        task.resume()
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
