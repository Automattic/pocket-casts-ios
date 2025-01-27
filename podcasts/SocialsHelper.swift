
import Foundation

class SocialsHelper {
    class func openTwitter() {
        let urls = ["tweetbot:///user_profile/pocketcasts", "twitterrific:///profile?screen_name=pocketcasts", "twitter://user?screen_name=pocketcasts", "https://x.com/pocketcasts"]

        openUrls(urls: urls)
    }

    class func openInstagram() {
        let urls = ["instagram://user?username=pocketcasts", "https://www.instagram.com/pocketcasts/", ""]

        openUrls(urls: urls)
    }

    private class func openUrls(urls: [String]) {
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
