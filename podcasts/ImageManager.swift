import Foundation
import Kingfisher
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class ImageManager {
    static let sharedManager = ImageManager()

    // cache for network images
    private var networkImageCache = ImageCache(name: "networkImageCache")

    // search image cache, we limit this to 10MBs
    private var searchImageCache = ImageCache(name: "generalImageCache")

    // subscribed image cache, these we want to store for a longer period of time
    lazy var subscribedPodcastsCache: ImageCache = {
        let path = (NSHomeDirectory() as NSString).appendingPathComponent("Documents/artworkv3")
        let url = URL(fileURLWithPath: path)
        subscribedPodcastsCache = try! ImageCache(name: "subscribedPodcastsCache", cacheDirectoryURL: url)
        subscribedPodcastsCache.diskStorage.config.sizeLimit = UInt(400.megabytes)
        subscribedPodcastsCache.diskStorage.config.expiration = .days(365) // cache artwork for a full year, so that users don't have their artwork disappeared
        return subscribedPodcastsCache
    }()

    // user episode image cache
    private var userEpisodeCache = ImageCache(name: "userEpisodeImageCache")

    // Discover Cache
    private var discoverCache = ImageCache(name: "discoverCache")

    public var biggestPodcastImageSize: Int {
        availablePodcastImageSizes.max()!
    }

    private let availablePodcastImageSizes = [130, 210, 280, 340, 400, 420, 680, 960]

    // we store failed embed lookups in memory, just to stop us constantly parsing a file with no artwork for artwork
    private var failedEmbeddedLookups = [] as [String]

    init() {
        networkImageCache.diskStorage.config.expiration = .days(56) // 8 weeks

        searchImageCache.diskStorage.config.sizeLimit = UInt(10.megabytes)

        userEpisodeCache.diskStorage.config.sizeLimit = UInt(10.megabytes)
        userEpisodeCache.diskStorage.config.expiration = .days(365)

        discoverCache.diskStorage.config.expiration = .days(10)
        discoverCache.diskStorage.config.sizeLimit = UInt(50.megabytes)

        NotificationCenter.default.addObserver(self, selector: #selector(podcastAddedNotification(notification:)), name: Constants.Notifications.podcastAdded, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Discover Images

    func loadDiscoverImage(imageUrl: String, imageView: UIImageView, placeholderSize: PodcastThumbnailSize? = nil) {
        if let url = URL(string: imageUrl) {
            let image = (placeholderSize == nil) ? nil : placeHolderImage(placeholderSize!)
            let processor = Theme.sharedTheme.activeTheme == .radioactive ? radioactiveProcessor() : DefaultImageProcessor.default
            imageView.kf.setImage(with: url, placeholder: image, options: [.processor(processor), .targetCache(discoverCache), .transition(.fade(Constants.Animation.defaultAnimationTime))])
        }
    }

    func retrieveDiscoverImage(imageUrl: String, completionHandler: @escaping ((UIImage?) -> Void)) {
        let cache = discoverCache
        cache.retrieveImage(forKey: imageUrl) { result in
            do {
                let image = try result.get().image
                completionHandler(image)

                if let url = URL(string: imageUrl), image == nil {
                    // if we don't have the image, tell the system to try and cache it
                    let prefetcher = ImagePrefetcher(urls: [url], options: [.targetCache(self.discoverCache)])
                    prefetcher.start()
                }
            } catch {
                completionHandler(nil)
            }
        }
    }

    // MARK: - Network Images

    func loadNetworkImage(imageUrl: String, imageView: UIImageView, placeholderSize: PodcastThumbnailSize? = nil) {
        if let url = URL(string: imageUrl) {
            let image = (placeholderSize == nil) ? nil : placeHolderImage(placeholderSize!)
            imageView.kf.setImage(with: url, placeholder: image, options: [.targetCache(networkImageCache), .transition(.fade(Constants.Animation.defaultAnimationTime))])
        }
    }

    // MARK: - Other images

    func loadSearchImage(imageUrl: String, imageView: UIImageView, placeHolderImage: UIImage? = nil) {
        if let url = URL(string: imageUrl) {
            let processor = Theme.sharedTheme.activeTheme == .radioactive ? radioactiveProcessor() : DefaultImageProcessor.default
            imageView.kf.setImage(with: url, placeholder: placeHolderImage, options: [.processor(processor), .targetCache(searchImageCache), .transition(.fade(Constants.Animation.defaultAnimationTime))])
        }
    }

    func loadSearchImage(imageUrl: String, imageView: UIImageView, placeholderSize: PodcastThumbnailSize) {
        if let url = URL(string: imageUrl) {
            let image = placeHolderImage(placeholderSize)
            let processor = Theme.sharedTheme.activeTheme == .radioactive ? radioactiveProcessor() : DefaultImageProcessor.default
            imageView.kf.setImage(with: url, placeholder: image, options: [.processor(processor), .targetCache(searchImageCache), .transition(.fade(Constants.Animation.defaultAnimationTime))])
        }
    }

    // MARK: - Subscribed Podcast Images

    func loadImage(podcastUuid: String, imageView: UIImageView, size: PodcastThumbnailSize, showPlaceHolder: Bool) {
        let url = podcastUrl(imageSize: size, uuid: podcastUuid)
        let placeholderImage = showPlaceHolder ? placeHolderImage(size) : nil
        let processor = Theme.sharedTheme.activeTheme == .radioactive ? radioactiveProcessor() : DefaultImageProcessor.default
        imageView.kf.setImage(with: url, placeholder: placeholderImage, options: [.processor(processor), .targetCache(subscribedPodcastsCache), .transition(.fade(Constants.Animation.defaultAnimationTime))])
    }

    func loadImage(url urlString: String, imageView: UIImageView, size: PodcastThumbnailSize, showPlaceHolder: Bool) {
        let url = URL(string: urlString)!
        let placeholderImage = showPlaceHolder ? placeHolderImage(size) : nil
        let processor = (Theme.sharedTheme.activeTheme == .radioactive ? radioactiveProcessor() : DefaultImageProcessor.default) |> DownsamplingImageProcessor(size: CGSize(width: ImageManager.sizeFor(imageSize: size), height: ImageManager.sizeFor(imageSize: size)))
        imageView.kf.setImage(with: url, placeholder: placeholderImage, options: [.processor(processor), .targetCache(subscribedPodcastsCache), .transition(.fade(Constants.Animation.defaultAnimationTime))])
    }

    func setPlaceholder(imageView: UIImageView, size: PodcastThumbnailSize) {
        imageView.image = placeHolderImage(size)
    }

    func loadImage(episode: BaseEpisode, imageView: UIImageView, size: PodcastThumbnailSize) {
        if loadEmbeddedImageIfRequired(in: episode, into: imageView) {
            return
        }

        // if that doesn't work, or they haven't opted in, load the podcast artwork instead
        if let userEpisode = episode as? UserEpisode {
            loadUserEpisodeImage(uuid: userEpisode.uuid, imageView: imageView, size: size, completionHandler: nil)
        } else {
            let url = podcastUrl(imageSize: size, uuid: episode.parentIdentifier())
            // for larger images, avoid really obvious reload flashes by keeping whatever image is there currently while loading a new one
            let placeholder = (imageView.image != nil && size == .page) ? imageView.image : placeHolderImage(size)
            let processor = Theme.sharedTheme.activeTheme == .radioactive ? radioactiveProcessor() : DefaultImageProcessor.default
            imageView.kf.setImage(with: url, placeholder: placeholder, options: [.processor(processor), .targetCache(subscribedPodcastsCache), .transition(.fade(Constants.Animation.defaultAnimationTime))], progressBlock: nil) { [weak self] result in
                switch result {
                case .failure:
                    if size == .page {
                        imageView.image = self?.placeHolderImage(size)
                    }
                default: break
                }
            }
        }
    }

    func hasCachedImage(for uuid: String, size: PodcastThumbnailSize) -> Bool {
        let url = podcastUrl(imageSize: size, uuid: uuid)
        return subscribedPodcastsCache.isCached(forKey: url.absoluteString)
    }

    func cachedImageFor(podcastUuid: String, size: PodcastThumbnailSize) -> UIImage? {
        let url = podcastUrl(imageSize: size, uuid: podcastUuid)

        return retrieveImageFromCache(url: url, cache: subscribedPodcastsCache, fetchIfMissing: true)
    }

    func cachedImageForUserEpisode(episode: UserEpisode, size: PodcastThumbnailSize) -> UIImage? {
        let url = episode.urlForImage()

        return retrieveImageFromCache(url: url, cache: userEpisodeCache, fetchIfMissing: true)
    }

    private func retrieveImageFromCache(url: URL, cache: ImageCache, fetchIfMissing: Bool) -> UIImage? {
        let key = url.cacheKey

        if let image = cache.retrieveImageInMemoryCache(forKey: key) { return image }

        if !cache.diskStorage.isCached(forKey: key) {
            if fetchIfMissing {
                let prefetcher = ImagePrefetcher(resources: [url], options: [.targetCache(cache)])
                prefetcher.start()
            }

            return nil
        }

        do {
            let data = try Data(contentsOf: cache.diskStorage.cacheFileURL(forKey: key))
            let image = UIImage(data: data)

            return image
        } catch {
            FileLog.shared.addMessage("retrieveImageFromCache, exception caught while loading cached image from disk")
        }

        return nil
    }

    func imageForEpisode(_ episode: BaseEpisode, size: PodcastThumbnailSize, completionHandler: @escaping ((UIImage?) -> Void)) {
        if loadEmbeddedImageIfRequired(in: episode, completion: { image in
            completionHandler(image)
        }) {
            return
        }

        let imageURL: URL
        let imageCache: ImageCache
        if let userEpisode = episode as? UserEpisode {
            imageURL = userEpisode.urlForImage()
            imageCache = userEpisodeCache
        } else if let episode = episode as? Episode, let parentPodcast = episode.parentPodcast() {
            imageURL = podcastUrl(imageSize: size, uuid: parentPodcast.uuid)
            imageCache = subscribedPodcastsCache
        } else {
            completionHandler(nil)
            return
        }

        KingfisherManager.shared.retrieveImage(with: imageURL, options: [.targetCache(imageCache)]) { result in
            let image = try? result.get().image
            completionHandler(image)
        }
    }

    private func loadEmbeddedImageIfRequired(in episode: BaseEpisode, into imageView: UIImageView? = nil, completion: ((UIImage?) -> Void)? = nil) -> Bool {
        // if the user has opted to use embedded artwork, try to load that
        guard Settings.loadEmbeddedImages else {
            return false
        }

        if subscribedPodcastsCache.isCached(forKey: episode.uuid) {
            loadEmbeddedArtwork(forKey: episode.uuid, into: imageView, completion: completion)
            return true
        }

        // loading episode artwork from downloaded files can be an expensive operation, so check to see if it's previously failed for this episode
        if episode.downloaded(pathFinder: DownloadManager.shared), !failedEmbeddedLookups.contains(episode.uuid) {
            if let embeddedImage = SJMediaMetadataHelper.embeddedImageForFile(atPath: episode.pathToDownloadedFile(pathFinder: DownloadManager.shared)) {
                imageView?.image = embeddedImage
                completion?(embeddedImage)
                return true
            } else {
                failedEmbeddedLookups.append(episode.uuid)
                return false
            }
        }

        return false
    }

    private func loadEmbeddedArtwork(forKey key: String, into imageView: UIImageView? = nil, completion: ((UIImage?) -> Void)? = nil) {
        subscribedPodcastsCache.retrieveImage(forKey: key, options: .none) { result in
            switch result {
            case .success(let imageCache):
                imageView?.image = imageCache.image
                completion?(imageCache.image)
            default:
                break
            }
        }
    }

    // MARK: - UserEpisode Images

    func loadUserEpisodeImage(uuid: String, imageView: UIImageView, size: PodcastThumbnailSize, completionHandler: ((Bool) -> Void)?) {
        imageView.image = nil

        let userEpisode = DataManager.sharedManager.findUserEpisode(uuid: uuid)
        let imageSize = size == .page ? 960 : 280
        let url = userEpisode?.urlForImage(size: imageSize) ?? ServerHelper.userEpisodeDefaultImageUrl(isDark: Theme.isDarkTheme(), color: 1, size: imageSize)
        if url.isFileURL {
            let provider = LocalFileImageDataProvider(fileURL: url)
            imageView.kf.setImage(with: provider, placeholder: placeHolderImage(size), options: [.targetCache(userEpisodeCache), .transition(.fade(Constants.Animation.defaultAnimationTime))], completionHandler: { result in
                switch result {
                case .success:
                    completionHandler?(true)
                case .failure:
                    completionHandler?(false)
                }
            })
        } else {
            imageView.kf.setImage(with: url, placeholder: placeHolderImage(size), options: [.targetCache(userEpisodeCache), .transition(.fade(Constants.Animation.defaultAnimationTime))], completionHandler: { result in
                switch result {
                case .success:
                    completionHandler?(true)
                case .failure:
                    completionHandler?(false)
                }
            })
        }
    }

    func imageForUserEpisodeColor(color: Int, imageView: UIImageView, size: PodcastThumbnailSize, completionHandler: ((Bool) -> Void)?) {
        imageView.image = nil
        let imageSize = size == .page ? 960 : 280
        let url = ServerHelper.userEpisodeDefaultImageUrl(isDark: Theme.isDarkTheme(), color: color, size: imageSize)

        imageView.backgroundColor = AppTheme.userEpisodeColor(number: color)
        imageView.kf.setImage(with: url, placeholder: nil, options: [.targetCache(userEpisodeCache), .transition(.fade(Constants.Animation.defaultAnimationTime))], completionHandler: { result in

            switch result {
            case .success:
                completionHandler?(true)
            case .failure:
                completionHandler?(false)
            }
        })
    }

    func removeUserEpisodeImage(episode: UserEpisode, completionHandler: @escaping () -> Void) {
        let fileUrl = URL(fileURLWithPath: episode.pathToLocalImage())
        userEpisodeCache.removeImage(forKey: fileUrl.cacheKey, fromMemory: true, fromDisk: true, completionHandler: {
            if let serverUrl = episode.imageUrl {
                self.userEpisodeCache.removeImage(forKey: serverUrl, fromMemory: true, fromDisk: true, completionHandler: {
                    completionHandler()
                })
            } else {
                completionHandler()
            }
        })
    }

    // MARK: - Precaching

    func cacheImages(podcastUuid: String) {
        let urls = allUrlsFor(podcastUuid: podcastUuid)
        let prefetcher = ImagePrefetcher(resources: urls, options: [.targetCache(subscribedPodcastsCache)])
        prefetcher.start()
    }

    // this method is designed to be called on app startup (eg: regularly) to check if our image cache needs to be updated
    // it will only update images if the user is on WiFi and also has passed the minimum amount of time since the last refresh
    func updatePodcastImagesIfRequired() {
        if let lastRefreshTime = UserDefaults.standard.object(forKey: Constants.UserDefaults.lastImageRefreshTime) as? Date {
            if fabs(lastRefreshTime.timeIntervalSinceNow) < Constants.Values.minTimeBetweenPodcastImageUpdates {
                return // it's been too soon since the last image refresh, so do nothing
            }
        }

        if !NetworkUtils.shared.isConnectedToWifi() { return } // we don't auto update podcast images over the cell network

        UserDefaults.standard.set(Date(), forKey: Constants.UserDefaults.lastImageRefreshTime)

        DataManager.sharedManager.setAllPodcastImageVersions(to: 0)
        let prefetcher = ImagePrefetcher(resources: allPodcastUrls(), options: [.targetCache(subscribedPodcastsCache), .forceRefresh])
        prefetcher.start()
    }

    private func cacheAllPodcastImages() {
        let prefetcher = ImagePrefetcher(resources: allPodcastUrls(), options: [.targetCache(subscribedPodcastsCache)])
        prefetcher.start()
    }

    private func allPodcastUrls() -> [URL] {
        var urls = [URL]()
        for podcast in DataManager.sharedManager.allPodcasts(includeUnsubscribed: false) {
            let urlsForPodcast = allUrlsFor(podcastUuid: podcast.uuid)
            urls.append(contentsOf: urlsForPodcast)
        }

        return urls
    }

    private func radioactiveProcessor() -> ImageProcessor {
        let processor =
            BlendImageProcessor(blendMode: .color, alpha: 1, backgroundColor: UIColor(hex: "#808080").withAlphaComponent(0.5)) |>
            ColorControlsProcessor(brightness: 0.1, contrast: 1.3, saturation: 0, inputEV: 0.5) |>
            BlendImageProcessor(blendMode: .plusDarker, alpha: 1, backgroundColor: UIColor(hex: "#70E84E"))

        return processor
    }

    private func allUrlsFor(podcastUuid: String) -> [URL] {
        var urls = [URL]()
        urls.append(podcastUrl(imageSize: .list, uuid: podcastUuid))
        urls.append(podcastUrl(imageSize: .grid, uuid: podcastUuid))
        urls.append(podcastUrl(imageSize: .page, uuid: podcastUuid))

        return urls
    }

    // MARK: - Cleanup

    func clearPodcastCache(recacheWhenDone: Bool) {
        // clear out all the saved colors, since they might change when the images do
        DataManager.sharedManager.setAllPodcastImageVersions(to: 0)

        subscribedPodcastsCache.clearMemoryCache()
        subscribedPodcastsCache.clearDiskCache { [weak self] in
            guard let strongSelf = self else { return }

            if recacheWhenDone {
                strongSelf.cacheAllPodcastImages()
            }

            NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastImageReCacheRequired)
        }
    }

    func clearCache(podcastUuid: String, recacheWhenDone: Bool) {
        // reset the podcast color version, so it re-downloads that when re-caching the image if required
        DataManager.sharedManager.setPodcastImageVersion(podcastUuid: podcastUuid, version: 0)
        NotificationCenter.default.post(name: Constants.Notifications.podcastUpdated, object: podcastUuid)

        // list and card are the same image, so card is not in the list below
        let listUrl = podcastUrl(imageSize: .list, uuid: podcastUuid)
        subscribedPodcastsCache.removeImage(forKey: listUrl.cacheKey)

        let gridUrl = podcastUrl(imageSize: .grid, uuid: podcastUuid)
        subscribedPodcastsCache.removeImage(forKey: gridUrl.cacheKey)

        let pageUrl = podcastUrl(imageSize: .page, uuid: podcastUuid)
        subscribedPodcastsCache.removeImage(forKey: pageUrl.cacheKey, completionHandler: { [weak self] in
            guard let strongSelf = self else { return }

            if recacheWhenDone {
                strongSelf.cacheImages(podcastUuid: podcastUuid)
            }

            NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastImageReCacheRequired)
        })
    }

    // MARK: - Subscription Bundle Image

    func loadBundleImage(imageUrl: String, imageView: UIImageView, placeholderSize: PodcastThumbnailSize? = nil) {
        if let url = URL(string: imageUrl) {
            let image = (placeholderSize == nil) ? nil : placeHolderImage(placeholderSize!)
            imageView.kf.setImage(with: url, placeholder: image, options: [.targetCache(discoverCache), .transition(.fade(Constants.Animation.defaultAnimationTime))])
        }
    }

    // MARK: - Cancel support

    func cancelLoad(_ imageView: UIImageView) {
        imageView.kf.cancelDownloadTask()
    }

    // MARK: - Legacy

    func upgradeV2ToV3ArtworkFolder() {
        let path = (NSHomeDirectory() as NSString).appendingPathComponent("Documents/artworkv2")
        removeAllFiles(folder: path)

        // if on WiFi, recache the images to make it a more seamless transition, if not, they'll just get cached as people use the app
        if NetworkUtils.shared.isConnectedToWifi() {
            cacheAllPodcastImages()
        }
    }

    private func removeAllFiles(folder: String) {
        let fileManager = FileManager()
        guard let dirEnumerator = fileManager.enumerator(atPath: folder) else { return }

        let folderNS = folder as NSString
        for file in dirEnumerator {
            do {
                try fileManager.removeItem(atPath: folderNS.appendingPathComponent(file as! String))
            } catch {}
        }
    }

    // MARK: - Pre-cache newly added podcasts

    @objc private func podcastAddedNotification(notification: Notification) {
        if let podcastUuid = notification.object as? String {
            cacheImages(podcastUuid: podcastUuid)
        }
    }

    // MARK: - Placeholder Image

    func placeHolderImage(_ size: PodcastThumbnailSize) -> UIImage? {
        switch size {
        case .grid:
            let name = Theme.isDarkTheme() ? "noartwork-grid-dark" : "noartwork-grid"
            return UIImage(named: name)
        case .list:
            let name = Theme.isDarkTheme() ? "noartwork-list-dark" : "noartwork-list"
            return UIImage(named: name)
        case .page:
            let name = Theme.isDarkTheme() ? "noartwork-page-dark" : "noartwork-page"
            return UIImage(named: name)
        }
    }

    func podcastUrl(imageSize: PodcastThumbnailSize, uuid: String) -> URL {
        let sizeRequired = ImageManager.sizeFor(imageSize: imageSize)
        let closestSize = closestImageSize(sizeRequired: sizeRequired)

        return ServerHelper.imageUrl(podcastUuid: uuid, size: closestSize)
    }

    private func closestImageSize(sizeRequired: Int) -> Int {
        var closeness = 999
        var closestIndex = 0
        for (index, value) in availablePodcastImageSizes.enumerated() {
            let newCloseness = abs(sizeRequired - value)
            if newCloseness < closeness {
                closeness = newCloseness
                closestIndex = index
            }
        }

        return availablePodcastImageSizes[closestIndex]

        // you'd think you'd just be able to: //availablePodcastImageSizes.enumerated().min( by: { abs($0.1 - sizeRequired) < abs($1.1 - sizeRequired)} )!
        // but that's about 8x slower, which sucks because this gets called a lot in table views, oh well
    }

    class func sizeFor(imageSize: PodcastThumbnailSize) -> Int {
        switch imageSize {
        case .list:
            return Int(65.0 * UIScreen.main.scale)
        case .grid:
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let shortestSide = screenHeight > screenWidth ? screenWidth : screenHeight

            return Int(round(shortestSide * UIScreen.main.scale / 3.0))
        case .page:
            return Int(320.0 * UIScreen.main.scale)
        }
    }
}
