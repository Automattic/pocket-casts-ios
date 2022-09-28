import PocketCastsServer
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    override init() {
        super.init()

        if let imagesFolder = podcastImageFolder() {
            do {
                try FileManager.default.createDirectory(atPath: imagesFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {}
        }
    }

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {
            if let podcastUuid = bestAttemptContent.userInfo["podcast_uuid"] as? String, let podcastImageUrl = localUrlFor(podcastUuid: podcastUuid) {
                do {
                    let attachment = try UNNotificationAttachment(identifier: podcastUuid, url: podcastImageUrl, options: nil)
                    bestAttemptContent.attachments = [attachment]
                } catch {}
            }

            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func podcastImageFolder() -> String? {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, false)
        guard let cachePath = paths.first as NSString? else { return nil }

        let fullPath = cachePath.expandingTildeInPath as NSString
        return fullPath.appendingPathComponent("notif_images")
    }

    private func localUrlFor(podcastUuid: String) -> URL? {
        guard let podcastFolder = podcastImageFolder() as NSString? else { return nil }

        let imagePath = "\(podcastFolder.appendingPathComponent(podcastUuid)).jpg"
        if FileManager.default.fileExists(atPath: imagePath) {
            return URL(fileURLWithPath: imagePath)
        }

        let imageUrl = ServerHelper.imageUrl(podcastUuid: podcastUuid, size: 280)

        do {
            let imageData = try Data(contentsOf: imageUrl)
            try imageData.write(to: URL(fileURLWithPath: imagePath))

            return URL(fileURLWithPath: imagePath)
        } catch {}

        return nil
    }
}
