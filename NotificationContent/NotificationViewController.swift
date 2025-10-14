
import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    @IBOutlet var podcastImage: UIImageView!
    @IBOutlet var podcastTitle: UILabel!
    @IBOutlet var episodeTitle: UILabel!
    @IBOutlet var episodeLength: UILabel!
    @IBOutlet var episodeDescription: UILabel!

    private var timeFormatter: DateComponentsFormatter?

    override func viewDidLoad() {
        super.viewDidLoad()
        timeFormatter = DateComponentsFormatter()
        timeFormatter?.unitsStyle = .abbreviated
        timeFormatter?.allowedUnits = [.hour, .minute]
    }

    func didReceive(_ notification: UNNotification) {
        podcastTitle.text = notification.request.content.title
        episodeTitle.text = notification.request.content.body

        if let attachment = notification.request.content.attachments.first {
            do {
                if attachment.url.startAccessingSecurityScopedResource() {
                    let data = try Data(contentsOf: attachment.url)
                    podcastImage.image = UIImage(data: data)
                    attachment.url.stopAccessingSecurityScopedResource()
                }
            } catch {}
        } else {
            podcastImage.image = UIImage(named: "no-artwork")
        }

        if let description = notification.request.content.userInfo["episode_desc"] as? String {
            episodeDescription.text = description
        } else {
            episodeDescription.text = nil
        }

        if let length = notification.request.content.userInfo["episode_length"] as? Int, length > 0 {
            // the length is in seconds, so let's format it
            episodeLength.text = timeFormatter?.string(from: TimeInterval(length))
        } else {
            episodeLength.text = nil
        }
    }
}
