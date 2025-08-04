import SafariServices

extension UIApplication {
    /// Opens SFSafariViewController if the URL scheme is http or https. If not, opens using UIApplication.open(url)
    /// - Parameter url: The url to attempt to open
    func openSafariVCIfPossible(_ url: URL) {
        guard url.scheme == "http" || url.scheme == "https" else {
            open(url, options: [:], completionHandler: nil)
            return
        }

        let safariViewController = SFSafariViewController(with: url)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
        SceneHelper.rootViewController()?.present(safariViewController, animated: true, completion: nil)
    }
}
