import PocketCastsDataModel
import PocketCastsServer
import UIKit

class SharingHelper: NSObject {
    static let shared = SharingHelper()
    var activityController: UIActivityViewController?
    func shareLinkTo(podcast: Podcast, fromController: UIViewController, sourceRect: CGRect, sourceView: UIView) {
        AnalyticsHelper.sharedPodcast()

        let sharingUrl = podcast.shareURL
        activityController = UIActivityViewController(activityItems: [URL(string: sharingUrl)!], applicationActivities: nil)
        activityController?.completionWithItemsHandler = { _, _, _, _ in
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
        }

        guard let activityController = activityController else { return }
        fromController.present(activityController, animated: true, completion: {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
        })

        activityController.popoverPresentationController?.sourceView = sourceView
        activityController.popoverPresentationController?.sourceRect = sourceRect
    }

    func shareLinkToApp(fromController: UIViewController) {
        guard let sharingUrl = URL(string: ServerConstants.Urls.pocketcastsDotCom) else { return }

        activityController = UIActivityViewController(activityItems: [L10n.appShareText, sharingUrl], applicationActivities: nil)
        guard let activityController = activityController else { return }

        activityController.completionWithItemsHandler = { _, _, _, _ in
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
        }

        fromController.present(activityController, animated: true, completion: {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
        })

        activityController.popoverPresentationController?.sourceView = fromController.view

        // this is a hack, but the only place we use this is in SwiftUI on iPad, where there's no easy way to get a tap location, so approximate it to the middle of the view instead
        activityController.popoverPresentationController?.sourceRect = CGRect(x: fromController.view.bounds.midX, y: fromController.view.bounds.midY, width: 44, height: 44)
    }

    func shareLinkTo(podcast: Podcast, fromController: UIViewController, barButtonItem: UIBarButtonItem?) {
        AnalyticsHelper.sharedPodcast()

        let sharingUrl = podcast.shareURL
        activityController = UIActivityViewController(activityItems: [URL(string: sharingUrl)!], applicationActivities: nil)
        activityController?.completionWithItemsHandler = { _, _, _, _ in
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
        }

        guard let activityController = activityController else { return }

        fromController.present(activityController, animated: true, completion: {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
        })
        activityController.popoverPresentationController?.barButtonItem = barButtonItem
    }

    func shareLinkToPodcastList(name: String, url: String, fromController: UIViewController, barButtonItem: UIBarButtonItem?, completionHandler: (() -> Void)?) {
        AnalyticsHelper.sharedPodcastList()

        activityController = UIActivityViewController(activityItems: [URL(string: url)!], applicationActivities: nil)
        activityController?.completionWithItemsHandler = { _, _, _, _ in
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
        }

        guard let activityController = activityController else { return }

        fromController.present(activityController, animated: true) {
            completionHandler?()
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
        }
        activityController.popoverPresentationController?.barButtonItem = barButtonItem
    }

    func shareLinkTo(episode: Episode, shareTime: TimeInterval, fromController: UIViewController, barButtonItem: UIBarButtonItem?) {
        activityController = createActivityController(episode: episode, shareTime: shareTime)
        activityController?.completionWithItemsHandler = { _, _, _, _ in
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
        }

        guard let activityController = activityController else { return }

        fromController.present(activityController, animated: true, completion: {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
        })
        activityController.popoverPresentationController?.barButtonItem = barButtonItem
    }

    func shareLinkTo(episode: Episode, shareTime: TimeInterval, fromController: UIViewController, sourceRect: CGRect, sourceView: UIView?, showArrow: Bool = true) {
        activityController = createActivityController(episode: episode, shareTime: shareTime)
        activityController?.completionWithItemsHandler = { _, _, _, _ in
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
        }

        guard let activityController = activityController else { return }

        fromController.present(activityController, animated: true, completion: {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)

        })
        activityController.popoverPresentationController?.sourceView = sourceView
        activityController.popoverPresentationController?.sourceRect = sourceRect

        if !showArrow {
            activityController.popoverPresentationController?.permittedArrowDirections = []
        }
    }

    func createActivityController(episode: Episode, shareTime: TimeInterval) -> UIActivityViewController {
        var sharingUrl = episode.shareURL
        if shareTime > 0 {
            AnalyticsHelper.sharedEpisodeWithTimestamp()
            sharingUrl += "?t=\(round(episode.playedUpTo))"
        } else {
            AnalyticsHelper.sharedEpisode()
        }

        let activityController = UIActivityViewController(activityItems: [URL(string: sharingUrl)!], applicationActivities: nil)
        activityController.completionWithItemsHandler = { _, _, _, _ in
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
        }
        return activityController
    }
}

extension Podcast {
    var shareURL: String {
        "\(ServerConstants.Urls.share())podcast/\(uuid)"
    }
}

extension Episode {
    var shareURL: String {
        "\(ServerConstants.Urls.share())episode/\(uuid)"
    }
}
