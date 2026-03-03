import GoogleCast
import PocketCastsDataModel
import PocketCastsServer
import UIKit

class GoogleCastManager: NSObject, GCKRemoteMediaClientListener, GCKSessionManagerListener, GCKCastDeviceStatusListener {
    static let sharedManager = GoogleCastManager()

    let deviceManager = CastDevicesManager()

    private let castAppId = "2FA4D21B"
    private let episodeUuidKey = "EPISODE_UUID"

    private let googleCastMaxPlaybackRate: Float = 2

    private var episodeToPlayOnConnect: BaseEpisode?

    private var pausing = false
    private var bufferingInitialPartOfEpisode = false
    private var clientReconnectOccured = false
    private var episodeUuidLoadedOnConnect = ""

    private var multiZoneDevices: [GCKMultizoneDevice]?

    // MARK: - Public functions

    func setup() {
        let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: castAppId))
        options.physicalVolumeButtonsWillControlDeviceVolume = true
        options.disableAnalyticsLogging = true
        GCKLogger.sharedInstance().loggingEnabled = false
        GCKCastContext.setSharedInstanceWith(options)

        GCKCastContext.sharedInstance().sessionManager.add(self)
        GCKCastContext.sharedInstance().discoveryManager.add(deviceManager)
    }

    func teardown() {
        GCKCastContext.sharedInstance().sessionManager.remove(self)
        GCKCastContext.sharedInstance().discoveryManager.remove(deviceManager)
    }

    func startDeviceDiscovery() {
        GCKCastContext.sharedInstance().discoveryManager.startDiscovery()
    }

    func stopDeviceDiscovery() {
        GCKCastContext.sharedInstance().discoveryManager.stopDiscovery()
    }

    func connectToDevice(_ device: GCKDevice) {
        GCKCastContext.sharedInstance().sessionManager.startSession(with: device)
    }

    func connectedDevice() -> GCKDevice? {
        GCKCastContext.sharedInstance().sessionManager.currentCastSession?.device
    }

    func changeVolume(to volume: Float) {
        GCKCastContext.sharedInstance().sessionManager.currentCastSession?.setDeviceVolume(volume)
    }

    func currentVolume() -> Float {
        GCKCastContext.sharedInstance().sessionManager.currentCastSession?.currentDeviceVolume ?? 0
    }

    func changeDeviceVolume(device: GCKMultizoneDevice, volume: Float) {
        guard let castSession = GCKCastContext.sharedInstance().sessionManager.currentSession as? GCKCastSession else { return }

        castSession.setDeviceVolume(volume, for: device)
    }

    func stopCasting() {
        GCKCastContext.sharedInstance().sessionManager.endSessionAndStopCasting(true)
    }

    func connectedOrConnectingToDevice() -> Bool {
        guard let currentSession = GCKCastContext.sharedInstance().sessionManager.currentSession else { return false }

        return (currentSession.connectionState == .connected || currentSession.connectionState == .connecting)
    }

    func requestMultizoneUpdate() {
        guard let currentSession = GCKCastContext.sharedInstance().sessionManager.currentSession as? GCKCastSession else { return }

        currentSession.requestMultizoneStatus()
    }

    func allMultiZoneDevices() -> [GCKMultizoneDevice]? {
        multiZoneDevices
    }

    func connected() -> Bool {
        guard let currentSession = GCKCastContext.sharedInstance().sessionManager.currentSession else { return false }

        return (currentSession.connectionState == .connected)
    }

    func connecting() -> Bool {
        guard let currentSession = GCKCastContext.sharedInstance().sessionManager.currentSession else { return false }

        return (currentSession.connectionState == .connecting)
    }

    func playing() -> Bool {
        if bufferingInitialPartOfEpisode { return true }

        if pausing { return false }

        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession else { return false }

        if let playerState = session.remoteMediaClient?.mediaStatus?.playerState {
            return playerState == .playing || playerState == .buffering
        }

        return false
    }

    func hasCastSession() -> Bool {
        return GCKCastContext.sharedInstance().sessionManager.currentCastSession != nil
    }

    func buffering() -> Bool {
        if bufferingInitialPartOfEpisode { return true }

        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession else { return false }

        if let playerState = session.remoteMediaClient?.mediaStatus?.playerState {
            return playerState == .buffering
        }

        return false
    }

    func changePlaybackSpeed(_ speed: Float) {
        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession else { return }

        let adjustedSpeed = min(googleCastMaxPlaybackRate, speed)
        session.remoteMediaClient?.setPlaybackRate(adjustedSpeed)
    }

    func play() {
        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession else { return }

        pausing = false
        session.remoteMediaClient?.play()
    }

    func pause() {
        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession else { return }

        pausing = true
        session.remoteMediaClient?.pause()
    }

    func endPlayback() {
        episodeToPlayOnConnect = nil
        pausing = true

        // turns out end casting needs to be called on the main thread
        if Thread.isMainThread {
            endCasting()
        } else {
            DispatchQueue.main.sync { [weak self] () in
                guard let strongSelf = self else { return }

                strongSelf.endCasting()
            }
        }
    }

    private func endCasting() {
        if let currentSession = GCKCastContext.sharedInstance().sessionManager.currentSession, currentSession.connectionState == .connected {
            currentSession.end(with: .stopCasting)
        }
    }

    func playSingleEpisode(_ episode: BaseEpisode) {
        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession else { return }

        // if we loaded this episode on connect and it's still playing it, no need to tell it to play again
        if episodeUuidLoadedOnConnect == episode.uuid, let playerState = session.remoteMediaClient?.mediaStatus?.playerState, playerState == .playing {
            episodeUuidLoadedOnConnect = ""
            return
        }

        episodeToPlayOnConnect = episode
        bufferingInitialPartOfEpisode = true

        // metadata about the episode to display on the Google Cast
        let episodeMetadata = GCKMediaMetadata(metadataType: episode.videoPodcast() ? .movie : .musicTrack)

        if let episode = episode as? Episode, let uuid = episode.parentPodcast()?.uuid {
            let episodeImage = GCKImage(url: ServerHelper.imageUrl(podcastUuid: uuid, size: 680), width: 680, height: 680)
            episodeMetadata.addImage(episodeImage)
        } else if let episode = episode as? UserEpisode {
            let url = episode.urlForImage(size: 960)
            let episodeImage = GCKImage(url: url, width: 960, height: 960)
            episodeMetadata.addImage(episodeImage)
        }

        let title = episode.subTitle()
        episodeMetadata.setString(title, forKey: kGCKMetadataKeyTitle)
        episodeMetadata.setString(title, forKey: kGCKMetadataKeySubtitle)
        episodeMetadata.setString(title, forKey: kGCKMetadataKeyAlbumTitle)

        if let episode = episode as? Episode, let author = episode.parentPodcast()?.author {
            episodeMetadata.setString(author, forKey: kGCKMetadataKeyAlbumArtist)
        }

        episodeMetadata.setString(episode.displayableTitle(), forKey: kGCKMetadataKeyTitle)

        // custom data that things like the iOS and Android app know to look for
        let episodeInfo = [episodeUuidKey: episode.uuid]
        let downloadUrl = EpisodeManager.urlForEpisode(episode, streamingOnly: true)
        let fileType = episode.fileType ?? ""
        let mediaBuilder = GCKMediaInformationBuilder()
        mediaBuilder.contentURL = downloadUrl
        mediaBuilder.streamType = .buffered
        mediaBuilder.contentType = fileType
        mediaBuilder.metadata = episodeMetadata
        mediaBuilder.streamDuration = episode.duration
        mediaBuilder.customData = episodeInfo
        let mediaInfo = mediaBuilder.build()

        pausing = false
        let loadOptions = GCKMediaLoadOptions()

        let adjustedSpeed = min(googleCastMaxPlaybackRate, Float(PlaybackManager.shared.effects().playbackSpeed))
        loadOptions.autoplay = true
        loadOptions.playPosition = PlaybackManager.shared.requiredStartingPosition()
        loadOptions.playbackRate = adjustedSpeed
        session.remoteMediaClient?.loadMedia(mediaInfo, with: loadOptions)
    }

    func canSeekToTime() -> Bool {
        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession else { return false }

        if let playerState = session.remoteMediaClient?.mediaStatus?.playerState {
            return playerState == .playing || playerState == .paused
        }

        return false
    }

    func seekToTime(_ time: TimeInterval) {
        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession else { return }

        if !canSeekToTime() { return }

        let seekOptions = GCKMediaSeekOptions()
        seekOptions.interval = time
        session.remoteMediaClient?.seek(with: seekOptions)
    }

    func streamPosition() -> TimeInterval {
        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession, let mediaClient = session.remoteMediaClient else {
            if let episode = episodeToPlayOnConnect {
                return episode.playedUpTo
            }

            return -1
        }

        return mediaClient.approximateStreamPosition()
    }

    func streamDuration() -> TimeInterval {
        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession else {
            if let episode = episodeToPlayOnConnect {
                return episode.duration
            }

            return -1
        }

        if let mediaInfo = session.remoteMediaClient?.mediaStatus?.mediaInformation {
            return mediaInfo.streamDuration
        }

        if let playerEpisode = PlaybackManager.shared.currentEpisode() {
            return playerEpisode.duration
        }

        return -1
    }

    // MARK: - GCKRemoteMediaClientListener

    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        guard let mediaStatus = mediaStatus else { return }
        AnalyticsPlaybackHelper.shared.currentSource = .chromecast

        if mediaStatus.playerState == .playing {
            if bufferingInitialPartOfEpisode {
                bufferingInitialPartOfEpisode = false
            }
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.playbackStarted)
        } else if mediaStatus.playerState == .paused {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.playbackPaused)
        } else if mediaStatus.playerState == .idle, mediaStatus.idleReason == .finished {
            PlaybackManager.shared.playerDidFinishPlayingEpisode()
        }
    }

    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaMetadata: GCKMediaMetadata?) {
        if clientReconnectOccured {
            clientReconnectOccured = false
            guard let customData = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient?.mediaStatus?.mediaInformation?.customData as? [String: String] else { return }

            if let playingEpisodeUuid = customData[episodeUuidKey] {
                episodeUuidLoadedOnConnect = playingEpisodeUuid
                AnalyticsPlaybackHelper.shared.currentSource = .chromecast
                PlaybackManager.shared.remoteDeviceAutoConnected(episodeUuidLoadedOnConnect)
            }
        }
    }

    // MARK: - GCKSession Events

    func castSession(_ castSession: GCKCastSession, didReceive multizoneStatus: GCKMultizoneStatus) {
        multiZoneDevices = multizoneStatus.devices
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.googleCastMultiZoneStatusChanged)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, willStart session: GCKSession) {
        if let castSession = session as? GCKCastSession {
            castSession.add(self)
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.googleCastStatusChanged)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.googleCastStatusChanged)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKCastSession) {
        session.remove(self)
        PlaybackManager.shared.remoteDeviceWillDisconnect()
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.googleCastStatusChanged)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.googleCastStatusChanged)
        PlaybackManager.shared.remoteDeviceDisconnected()
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
        if let castSession = session as? GCKCastSession {
            castSession.add(self)
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.googleCastStatusChanged)
    }

    // MARK: - GCKCastSession Events

    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        startMonitoring(session)
        PlaybackManager.shared.remoteDeviceConnected()
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        stopMonitoring(session)
        PlaybackManager.shared.remoteDeviceDisconnected()
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        clientReconnectOccured = true

        startMonitoring(session)
    }

    private func startMonitoring(_ castSession: GCKCastSession) {
        castSession.remoteMediaClient?.remove(self)
        castSession.remoteMediaClient?.add(self)
    }

    private func stopMonitoring(_ castSession: GCKCastSession) {
        castSession.remoteMediaClient?.remove(self)
    }
}
