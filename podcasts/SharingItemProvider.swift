import UIKit

class SharingItemProvider: UIActivityItemProvider {
    private var sharingString: String

    init(sharingString: String) {
        self.sharingString = sharingString
        super.init(placeholderItem: sharingString)
    }

    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        // return the sharing string containing the podcast and episode name, but only to services where it makes sense
        if activityType == .postToFacebook || activityType == .postToTwitter || activityType == .postToWeibo || activityType == .message || activityType == .mail || activityType == .postToTencentWeibo {
            return sharingString
        }

        // for things like copy link, give them just the link instead
        return nil
    }

    override func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        ""
    }
}
