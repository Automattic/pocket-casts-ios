import UIKit

class StoryShareableText: UIActivityItemProvider {
    private var text: String

    private let hashtags = "#pocketcasts #endofyear2022"

    init(_ text: String) {
        self.text = text
        super.init(placeholderItem: "\(text) \(hashtags)")
    }

    override var item: Any {
        text
    }
}
