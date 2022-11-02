import PocketCastsDataModel
import PocketCastsServer
import UIKit

class ColorManager {
    private let defaultBackgroundColor = UIColor(hex: "#3D3D3D")
    private let defaultLightTintColor = UIColor(hex: "#1E1F1E")
    private let defaultDarkTintColor = UIColor(hex: "#FFFFFF")

    private let defaultServerLightTint = "#F44336"
    private let defaultServerDarkTint = "#C62828"

    // the amount of time to leave between color refresh attempts. This is quite low (30 min) because we write out defaults for shows that are missing artwork, so this should always be present
    private let minTimeBetweenColorRefreshAttempts = 30.minutes

    private let currentColorVersion = 4 as Int32

    private let colorDownloadQueue = OperationQueue()

    private let lock = NSObject()
    private var downloadingPodcasts = [String]()

    static let sharedManager = ColorManager()

    private init() {
        colorDownloadQueue.maxConcurrentOperationCount = 5
    }

    class func podcastHasBackgroundColor(_ podcast: Podcast) -> Bool {
        ColorManager.sharedManager.podcastHasBackgroundColor(podcast)
    }

    class func backgroundColorForPodcast(_ podcast: Podcast) -> UIColor {
        ColorManager.sharedManager.backgroundColorForPodcast(podcast)
    }

    class func backgroundColorForPodcastUuid(_ uuid: String) -> UIColor {
        guard let podcast = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) else {
            return ColorManager.sharedManager.defaultBackgroundColor
        }
        return ColorManager.sharedManager.backgroundColorForPodcast(podcast)
    }

    class func darkThemeTintColorForPodcastUuid(_ uuid: String, completion: @escaping ((UIColor) -> Void)) {
        CacheServerHandler.shared.loadPodcastColors(podcastUuid: uuid, allowCachedVersion: true, completion: { _, _, darkThemeTint in
            guard let darkThemeTint = darkThemeTint else {
                completion(ColorManager.sharedManager.defaultDarkTintColor)

                return
            }

            completion(UIColor(hex: darkThemeTint))
        })
    }

    class func lightThemeTintForPodcast(_ podcast: Podcast, defaultColor: UIColor? = nil) -> UIColor {
        ColorManager.sharedManager.lightThemeTintForPodcast(podcast, defaultColor: defaultColor)
    }

    class func darkThemeTintForPodcast(_ podcast: Podcast, defaultColor: UIColor? = nil) -> UIColor {
        ColorManager.sharedManager.darkThemeTintForPodcast(podcast, defaultColor: defaultColor)
    }

    private func podcastHasBackgroundColor(_ podcast: Podcast) -> Bool {
        podcast.backgroundColor != nil && podcast.colorVersion == currentColorVersion
    }

    func updateColorsIfRequired(_ podcast: Podcast) {
        if podcast.colorVersion < currentColorVersion {
            scheduleColorDownload(podcast)
        }
    }

    private func backgroundColorForPodcast(_ podcast: Podcast) -> UIColor {
        if let colorStr = podcast.backgroundColor, podcast.colorVersion == currentColorVersion {
            return UIColor(hex: colorStr)
        }

        updateColorsIfRequired(podcast)

        return defaultBackgroundColor
    }

    private func lightThemeTintForPodcast(_ podcast: Podcast, defaultColor: UIColor? = nil) -> UIColor {
        if let colorStr = podcast.primaryColor, podcast.colorVersion == currentColorVersion {
            if colorStr == defaultServerLightTint {
                return defaultColor ?? defaultLightTintColor
            }

            return UIColor(hex: colorStr)
        }

        updateColorsIfRequired(podcast)

        return defaultColor ?? defaultLightTintColor
    }

    private func darkThemeTintForPodcast(_ podcast: Podcast, defaultColor: UIColor? = nil) -> UIColor {
        if let colorStr = podcast.secondaryColor, podcast.colorVersion == currentColorVersion {
            if colorStr == defaultServerDarkTint {
                return defaultColor ?? defaultDarkTintColor
            }

            return UIColor(hex: colorStr)
        }

        updateColorsIfRequired(podcast)

        return defaultColor ?? defaultDarkTintColor
    }

    private func removeDownloadingUuid(_ podcastUuid: String) {
        objc_sync_enter(lock)

        if let removeIndex = downloadingPodcasts.firstIndex(of: podcastUuid) {
            downloadingPodcasts.remove(at: removeIndex)
        }

        objc_sync_exit(lock)
    }

    private func addDownloadingUuid(_ podcastUuid: String) -> Bool {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }

        if downloadingPodcasts.contains(podcastUuid) {
            return false
        }

        downloadingPodcasts.append(podcastUuid)

        return true
    }

    private func scheduleColorDownload(_ podcast: Podcast) {
        if !addDownloadingUuid(podcast.uuid) { return }

        // make sure we don't re-download in a short period of time
        if podcast.lastColorDownloadDate != nil, abs(podcast.lastColorDownloadDate!.timeIntervalSinceNow) < minTimeBetweenColorRefreshAttempts {
            removeDownloadingUuid(podcast.uuid)

            return // not enough time since we last tried to load colors for this podcast
        }

        let podcastUuid = podcast.uuid
        colorDownloadQueue.addOperation { [weak self] in
            guard let strongSelf = self else { return }

            // we set this up so that we can wait for the async request to finish before returning out of thread
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()

            CacheServerHandler.shared.loadPodcastColors(podcastUuid: podcastUuid, allowCachedVersion: false, completion: { backgroundColor, lightThemeTint, darkThemeTint in
                guard let backgroundColor = backgroundColor, let lightThemeTint = lightThemeTint, let darkThemeTint = darkThemeTint else {
                    strongSelf.handleDownloadError(podcastUuid: podcastUuid)
                    dispatchGroup.leave()

                    return
                }

                if let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true) {
                    podcast.backgroundColor = backgroundColor
                    podcast.primaryColor = lightThemeTint
                    podcast.secondaryColor = darkThemeTint
                    podcast.colorVersion = strongSelf.currentColorVersion
                    podcast.lastColorDownloadDate = Date()
                    DataManager.sharedManager.save(podcast: podcast)

                    strongSelf.colorsDidSave(podcastUuid: podcastUuid)
                }
                dispatchGroup.leave()
            })

            dispatchGroup.wait()
        }
    }

    private func colorsDidSave(podcastUuid: String) {
        removeDownloadingUuid(podcastUuid)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastColorsDownloaded, object: podcastUuid)
    }

    private func handleDownloadError(podcastUuid: String) {
        if let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true) {
            podcast.lastColorDownloadDate = Date()
            DataManager.sharedManager.save(podcast: podcast)
        }

        removeDownloadingUuid(podcastUuid)
    }
}
