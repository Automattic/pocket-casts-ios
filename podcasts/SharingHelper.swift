import PocketCastsDataModel
import PocketCastsServer
import UIKit
import PocketCastsUtils

class SharingHelper: NSObject {
    static let shared = SharingHelper()
    var activityController: UIActivityViewController?
    func shareLinkTo(podcast: Podcast, fromController: UIViewController, fromSource: AnalyticsSource, sourceRect: CGRect, sourceView: UIView) {

        guard !podcast.isPrivate else {
            Toast.show(L10n.sharePodcastPrivateNotAvailable)
            return
        }

        AnalyticsHelper.sharedPodcast()

        SharingModal.show(option: .podcast(podcast), from: fromSource, in: fromController)
    }

    func shareLinkToApp(fromController: UIViewController) {
        guard let sharingUrl = URL(string: ServerConstants.Urls.pocketcastsDotCom) else { return }

        activityController = UIActivityViewController(activityItems: [L10n.appShareText, sharingUrl], applicationActivities: nil)
        guard let activityController = activityController else { return }

        activityController.completionWithItemsHandler = nil

        fromController.present(activityController, animated: true)

        activityController.popoverPresentationController?.sourceView = fromController.view

        // this is a hack, but the only place we use this is in SwiftUI on iPad, where there's no easy way to get a tap location, so approximate it to the middle of the view instead
        activityController.popoverPresentationController?.sourceRect = CGRect(x: fromController.view.bounds.midX, y: fromController.view.bounds.midY, width: 44, height: 44)
    }

    func shareLinkTo(podcast: Podcast, fromController: UIViewController, fromSource: AnalyticsSource, barButtonItem: UIBarButtonItem?) {
        AnalyticsHelper.sharedPodcast()

        SharingModal.show(option: .podcast(podcast), from: fromSource, in: fromController)
    }

    func shareLinkToPodcastList(name: String, url: String, fromController: UIViewController, barButtonItem: UIBarButtonItem?, completionHandler: (() -> Void)?) {
        AnalyticsHelper.sharedPodcastList()

        activityController = UIActivityViewController(activityItems: [URL(string: url)!], applicationActivities: nil)
        activityController?.completionWithItemsHandler = nil

        guard let activityController = activityController else { return }

        fromController.present(activityController, animated: true) {
            completionHandler?()
        }
        activityController.popoverPresentationController?.barButtonItem = barButtonItem
    }

    func shareLinkTo(episode: Episode, shareTime: TimeInterval, fromController: UIViewController, fromSource: AnalyticsSource, barButtonItem: UIBarButtonItem?) {
        let option: SharingModal.Option = shareTime == 0 ? .episode(episode) : .currentPosition(episode, shareTime)
        SharingModal.show(option: option, from: fromSource, in: fromController)
    }

    func shareLinkTo(episode: Episode, shareTime: TimeInterval, fromController: UIViewController, sourceRect: CGRect, sourceView: UIView?, showArrow: Bool = true, fromSource: AnalyticsSource, analyticsType: String = "episode") {
        let option: SharingModal.Option = shareTime == 0 ? .episode(episode) : .currentPosition(episode, shareTime)
        SharingModal.show(option: option, from: fromSource, in: fromController)
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
        activityController.completionWithItemsHandler = nil
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
