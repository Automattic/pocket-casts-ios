
import Foundation
import UIKit

enum SocialsHelper {
    static func openTwitter() {
        let urls = ["tweetbot:///user_profile/pocketcasts", "twitterrific:///profile?screen_name=pocketcasts", "twitter://user?screen_name=pocketcasts", "https://x.com/pocketcasts"]

        openUrls(urls: urls)
    }

    static func openInstagram() {
        let urls = ["instagram://user?username=pocketcasts", "https://www.instagram.com/pocketcasts/", ""]

        openUrls(urls: urls)
    }

    static func openBluesky() {
        let urls = ["bluesky://profile/pocketcasts.com", "https://bsky.app/profile/pocketcasts.com"]

        openUrls(urls: urls)
    }

    private static func openUrls(urls: [String]) {
        let application = UIApplication.shared
        for urlString in urls {
            if let url = URL(string: urlString) {
                if application.canOpenURL(url) {
                    application.open(url, options: [:], completionHandler: nil)

                    return
                }
            }
        }
    }
}
