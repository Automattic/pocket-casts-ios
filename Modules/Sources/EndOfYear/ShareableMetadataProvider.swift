import UIKit
import UniformTypeIdentifiers
import PocketCastsServer
import PocketCastsDataModel

public protocol ShareableMetadataDataSource: AnyObject {
    /// Create a provider to handle the additional meta data needed
    var shareableMetadataProvider: ShareableMetadataProvider { get }

    /// Returns the link that we should share in the metadata
    var shareableLink: String { get }

    /// Returns the array of hashtags to share
    var hashtags: [String] { get }
}

public class ShareableMetadataProvider: UIActivityItemProvider {
    public weak var dataSource: ShareableMetadataDataSource?

    public init() {
        super.init(placeholderItem: "")
    }

    override public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        guard let dataSource, let activityType, activityType.supportsShareableMetadata else { return nil }

        let item = NSExtensionItem()

        // Provide tags using the x-extension format
        // Ref: https://github.com/tumblr/XExtensionItem
        // We don't need the entire library so we're just including what we need
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

    public var supportsShareableMetadata: Bool {
        return self == .postToTumblr
    }
}
