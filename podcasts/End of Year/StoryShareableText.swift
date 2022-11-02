import UIKit

class StoryShareableText: UIActivityItemProvider {
    private var text: String

    private let hashtags = "#pocketcasts #endofyear2022"

    private let pocketCastsUrl = "https://pca.st/"

    init(_ text: String) {
        self.text = "\(text) \(hashtags) \(pocketCastsUrl)"
        super.init(placeholderItem: self.text)
    }

    override var item: Any {
        text
    }
}
