import UIKit

class StoryShareableText: UIActivityItemProvider {
    private var text: String

    private let hashtags = "#pocketcasts #endofyear2022"

    init(_ text: String) {
        self.text = "\(text) \(hashtags)"
        super.init(placeholderItem: self.text)
    }

    override var item: Any {
        text
    }
}
