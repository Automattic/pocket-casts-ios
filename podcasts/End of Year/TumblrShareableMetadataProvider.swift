import Foundation
import PocketCastsServer
import PocketCastsDataModel

protocol TumblrDataSource: AnyObject {
    /// Create a provider to handle the additional meta data needed
    var tumblrItemProvider: TumblrShareableMetadataProvider { get }

    /// Returns the link that we should share in the metadata
    var shareableLink: String { get }

    /// Returns the array of hashtags to share
    var hashtags: [String] { get }
}

class TumblrShareableMetadataProvider: UIActivityItemProvider {
    weak var dataSource: TumblrDataSource?

    init() {
        super.init(placeholderItem: "")
    }

    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        guard let dataSource, activityType == .postToTumblr else { return nil }

        let item = NSExtensionItem()

        // Provide tags to Tumblr using the x-extension format
        item.userInfo = [
            "x-extension-item": [
                "tags": dataSource.hashtags
            ]
        ]

        // Send the links as attachments
        item.attachments = [
            NSItemProvider(item: NSURL(string: dataSource.shareableLink), typeIdentifier: UTType.url.identifier)
        ]

        return item
    }
}

extension UIActivity.ActivityType {
    public static let postToTumblr = UIActivity.ActivityType(rawValue: "com.tumblr.tumblr.share")
}
