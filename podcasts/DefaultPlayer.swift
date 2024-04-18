import AVFoundation
import CoreAudioTypes
import Foundation
import PocketCastsDataModel
import PocketCastsUtils

class DefaultPlayer: PlaybackProtocol, Hashable {
    private var audioMix: AVAudioMix?
    private var assetTrack: AVAssetTrack?

    private var player: AVPlayer?

    private var requiredPlaybackRate: Double = 0
    private var shouldKeepPlaying = false
    private var volumeBoostEnabled = false

    private var lastBackgroundedDate: Date?

    /// Internal flag that keeps track of whether we're waiting for the initial playback to begin
    private var isWaitingForInitialPlayback = false

    // Keep track of the previous playback and waiting state
    private var previousReasonForWaiting: AVPlayer.WaitingReason?
    private var previousTimeControlStatus: AVPlayer.TimeControlStatus?

    private var durationObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?
    private var playerStatusObserver: NSKeyValueObservation?
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var timeControlStatusObserver: NSKeyValueObservation?

    private var playToEndObserver: NSObjectProtocol?
    private var playFailedObserver: NSObjectProtocol?
    private var playStalledObserver: NSObjectProtocol?

    private var episodeUuid: String?
    private var podcastUuid: String?

    #if !os(watchOS)
        private lazy var episodeArtwork: EpisodeArtwork = {
            EpisodeArtwork()
        }()

        private var peakLimiter: AudioUnit?
        private var highPassFilter: AudioUnit?
        private var sampleCount: Float64 = 0
        private var backgroundTaskId: UIBackgroundTaskIdentifier
    #endif

    init() {
        #if !os(watchOS)
            backgroundTaskId = .invalid
            NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        #endif
    }

    func loadEpisode(_ episode: BaseEpisode) {
        if player != nil {
            cleanupPlayer()
            player = nil
        }

        guard let playerItem = PlaybackItem(episode: episode).createPlayerItem() else {
            handlePlaybackError("Unable to create playback item")
            return
        }

        isWaitingForInitialPlayback = true

        player = AVPlayer(playerItem: playerItem)

        episodeUuid = episode.uuid
        podcastUuid = episode.parentIdentifier()

        configurePlayer(videoPodcast: episode.videoPodcast())
    }

    func playing() -> Bool {
        (player?.rate ?? 0) != 0
    }

    func buffering() -> Bool {
        guard let player = player else { return false }

        if let item = player.currentItem {
            return item.isPlaybackBufferEmpty
        }

        return true
    }

    func futureBufferAvailable() -> TimeInterval {
        guard let loadedTimeRanges = player?.currentItem?.loadedTimeRanges else { return 0 }

        let upTo = currentTime()
        for range in loadedTimeRanges {
            let rangeBuferred = range.timeRangeValue
            if (CMTimeGetSeconds(rangeBuferred.start) + CMTimeGetSeconds(rangeBuferred.duration)) > upTo {
                return CMTimeGetSeconds(rangeBuferred.duration)
            }
        }

        return 0
    }

    func play(completion: (() -> Void)? = nil) {
        startBackgroundTask()

        shouldKeepPlaying = true
        effectsDidChange()
        performSetPlaybackRate()
        jumpToStartingPosition()

        completion?()
    }

    func pause() {
        shouldKeepPlaying = false
        player?.pause()
    }

    func playbackRate() -> Double {
        if let rate = player?.rate, rate > 0 {
            return Double(rate)
        }

        return requiredPlaybackRate
    }

    func setPlaybackRate(_ rate: Double) {
        requiredPlaybackRate = rate

        if playing() {
            performSetPlaybackRate()
        }
    }

    func seekTo(_ time: TimeInterval, completion: (() -> Void)?) {
        let adjustedTime = fmax(0.1, time)

        let timeToSeekTo = CMTimeMake(value: Int64(adjustedTime * 100), timescale: 100)
        let tolerance = CMTime.zero // in testing setting this to 1 second wasn't honoured and it would sometimes be 10 seconds out. So go for accuracy over seek speed here

        player?.seek(to: timeToSeekTo, toleranceBefore: tolerance, toleranceAfter: tolerance, completionHandler: { finished in
            if finished {
                if !self.playing(), self.shouldKeepPlaying {
                    self.play(completion: nil)
                }
                completion?()
            }
        })
    }

    func currentTime() -> TimeInterval {
        if let time = player?.currentTime() {
            return CMTimeGetSeconds(time)
        }

        return 0
    }

    func duration() -> TimeInterval {
        guard let duration = player?.currentItem?.duration, !duration.isIndefinite else {
            return -1
        }

        return CMTimeGetSeconds(duration)
    }

    func endPlayback(permanent: Bool) {
        shouldKeepPlaying = false
        if playing() {
            player?.pause()
        }
        cleanupPlayer()

        audioMix = nil
        assetTrack = nil
        player = nil
    }

    func effectsDidChange() {
        let effects = PlaybackManager.shared.effects()

        setPlaybackRate(effects.playbackSpeed)
        volumeBoostEnabled = effects.volumeBoost
    }

    func supportsSilenceRemoval() -> Bool {
        false
    }

    func supportsVolumeBoost() -> Bool {
        true
    }

    func supportsGoogleCast() -> Bool {
        false
    }

    func supportsStreaming() -> Bool {
        true
    }

    func supportsAirplay2() -> Bool {
        true
    }

    func shouldBePlaying() -> Bool {
        shouldKeepPlaying
    }

    func routeDidChange(shouldPause: Bool) {
        if shouldPause {
            PlaybackManager.shared.pause(userInitiated: false)
        }
    }

    func interruptionDidStart() {
        // we don't need to do anything here, iOS handles this
    }

    func internalPlayerForVideoPlayback() -> AVPlayer? {
        player
    }

    @objc private func didEnterBackground() {
        lastBackgroundedDate = Date()
    }

    private func playerStatusDidChange() {
        if player?.currentItem?.status == .failed {
            PlaybackManager.shared.playbackDidFail(logMessage: "AVPlayerItemStatusFailed on currentItem", userMessage: nil)

            return
        }

        if assetTrack == nil, player?.currentItem?.status == .readyToPlay, let tracks = player?.currentItem?.asset.tracks {
            loadEmbeddedImage()

            for track in tracks {
                if track.mediaType == AVMediaType.audio {
                    assetTrack = track
                    break
                }
            }

            #if !os(watchOS)
                createAudioMix()
                player?.currentItem?.audioMix = audioMix
            #endif

            isWaitingForInitialPlayback = false
        }

        PlaybackManager.shared.playerDidChangeNowPlayingInfo()
    }

    // MARK: - Audio Mix

    #if !os(watchOS)
        private func createAudioMix() {
            guard audioMix == nil else { return }

            let mutableMix = AVMutableAudioMix()
            let audioMixInputParameters = AVMutableAudioMixInputParameters(track: assetTrack)

            var callbacks = MTAudioProcessingTapCallbacks(
                version: kMTAudioProcessingTapCallbacksVersion_0,
                clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
                init: tapInit,
                finalize: tapFinalize,
                prepare: tapPrepare,
                unprepare: tapUnprepare,
                process: tapProcess
            )

            var audioProcessingTap: Unmanaged<MTAudioProcessingTap>?
            if noErr == MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PreEffects, &audioProcessingTap) {
                audioMixInputParameters.audioTapProcessor = audioProcessingTap?.takeRetainedValue()
                mutableMix.inputParameters = [audioMixInputParameters]
                audioMix = mutableMix
            }
        }

        // MARK: - Tap Callbacks

        let tapInit: MTAudioProcessingTapInitCallback = { tap, clientInfo, tapStorageOut in
            tapStorageOut.pointee = clientInfo

            let referenceToSelf = Unmanaged<DefaultPlayer>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
            referenceToSelf.peakLimiter = nil
            referenceToSelf.highPassFilter = nil
            referenceToSelf.sampleCount = 0
        }

        let tapFinalize: MTAudioProcessingTapFinalizeCallback = { _ in }

        let tapPrepare: MTAudioProcessingTapPrepareCallback = { tap, maxFrames, processingFormat in
            var referenceToSelf = Unmanaged<DefaultPlayer>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()

            guard let filter = referenceToSelf.createHighPassFilter(maxFrames: maxFrames, processingFormat: processingFormat.pointee) else {
                referenceToSelf.handlePlaybackError("Setup high pass filter failed")
                return
            }
            referenceToSelf.highPassFilter = filter

            guard let limiter = referenceToSelf.createPeakLimiter(maxFrames: maxFrames, processingFormat: processingFormat.pointee) else {
                referenceToSelf.handlePlaybackError("Setup peak limiter failed")
                return
            }
            referenceToSelf.peakLimiter = limiter
        }

        let tapUnprepare: MTAudioProcessingTapUnprepareCallback = { tap in
            var referenceToSelf = Unmanaged<DefaultPlayer>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
            if let peakLimiter = referenceToSelf.peakLimiter {
                AudioUnitUninitialize(peakLimiter)
                AudioComponentInstanceDispose(peakLimiter)
                referenceToSelf.peakLimiter = nil
            }

            if let highPassFilter = referenceToSelf.highPassFilter {
                AudioUnitUninitialize(highPassFilter)
                AudioComponentInstanceDispose(highPassFilter)
                referenceToSelf.highPassFilter = nil
            }
        }

        let tapProcess: MTAudioProcessingTapProcessCallback = { tap, numberFrames, _, bufferListInOut, numberFramesOut, flagsOut in
            var referenceToSelf = Unmanaged<DefaultPlayer>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()

            let currentSampleCount = referenceToSelf.sampleCount
            referenceToSelf.sampleCount += Float64(numberFrames)
            guard referenceToSelf.volumeBoostEnabled, let highPassFilter = referenceToSelf.highPassFilter, referenceToSelf.peakLimiter != nil else {
                // no effects enabled, so just play normally
                guard MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut) == noErr else {
                    referenceToSelf.handlePlaybackError("MTAudioProcessingTapGetSourceAudio failed")
                    return
                }

                return
            }

            // apply volume boost
            var audioTimeStamp = AudioTimeStamp()
            audioTimeStamp.mSampleTime = currentSampleCount
            audioTimeStamp.mFlags = AudioTimeStampFlags.sampleTimeValid
            guard AudioUnitRender(highPassFilter, nil, &audioTimeStamp, 0, UInt32(numberFrames), bufferListInOut) == noErr else {
                referenceToSelf.handlePlaybackError("AudioUnitRender failed")
                return
            }

            numberFramesOut.pointee = numberFrames
        }

        // MARK: - Peak Limter

        func createPeakLimiter(maxFrames: CMItemCount, processingFormat: AudioStreamBasicDescription) -> AudioUnit? {
            var componentDescription = AudioComponentDescription(componentType: kAudioUnitType_Effect,
                                                                 componentSubType: kAudioUnitSubType_PeakLimiter,
                                                                 componentManufacturer: kAudioUnitManufacturer_Apple,
                                                                 componentFlags: 0,
                                                                 componentFlagsMask: 0)

            var unit: AudioUnit?
            guard let audioComponent = AudioComponentFindNext(nil, &componentDescription) else { return nil }
            guard AudioComponentInstanceNew(audioComponent, &unit) == noErr, let createdUnit = unit else { return nil }

            // Set audio unit input/output stream format to processing format
            var format = processingFormat
            guard AudioUnitSetProperty(createdUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &format, UInt32(MemoryLayout<AudioStreamBasicDescription>.stride)) == noErr else { return nil }
            guard AudioUnitSetProperty(createdUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &format, UInt32(MemoryLayout<AudioStreamBasicDescription>.stride)) == noErr else { return nil }

            // Set audio unit render callback
            var renderCallback = AURenderCallbackStruct(inputProc: peakLimiterRenderCallback, inputProcRefCon: Unmanaged.passUnretained(self).toOpaque())
            guard AudioUnitSetProperty(createdUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, UInt32(MemoryLayout<AURenderCallbackStruct>.stride)) == noErr else { return nil }

            // Set audio unit maximum frames per slice to max frames
            var maximumFramesPerSlice = UInt32(maxFrames)
            guard AudioUnitSetProperty(createdUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, UInt32(MemoryLayout<UInt32>.stride)) == noErr else { return nil }

            // Initialize audio unit
            guard AudioUnitInitialize(createdUnit) == noErr else {
                AudioComponentInstanceDispose(createdUnit)
                return nil
            }

            AudioUnitSetParameter(createdUnit, kLimiterParam_AttackTime, kAudioUnitScope_Global, 0, 0.002, 0)
            AudioUnitSetParameter(createdUnit, kLimiterParam_DecayTime, kAudioUnitScope_Global, 0, 0.005, 0)
            AudioUnitSetParameter(createdUnit, kLimiterParam_PreGain, kAudioUnitScope_Global, 0, 8, 0)

            return createdUnit
        }

        let peakLimiterRenderCallback: AURenderCallback = { inRefCon, _, _, _, inNumberFrames, ioData -> OSStatus in
            if ioData == nil { return -1 }

            let referenceToSelf = unsafeBitCast(inRefCon, to: DefaultPlayer.self)
            guard let tap = referenceToSelf.audioMix?.inputParameters.first?.audioTapProcessor else { return -1 }

            // The peak limiter is at the end of the chain so just grab the processed audio
            return MTAudioProcessingTapGetSourceAudio(tap, CMItemCount(inNumberFrames), ioData!, nil, nil, nil)
        }

        // MARK: - High Pass Filter

        func createHighPassFilter(maxFrames: CMItemCount, processingFormat: AudioStreamBasicDescription) -> AudioUnit? {
            var componentDescription = AudioComponentDescription(componentType: kAudioUnitType_Effect,
                                                                 componentSubType: kAudioUnitSubType_HighPassFilter,
                                                                 componentManufacturer: kAudioUnitManufacturer_Apple,
                                                                 componentFlags: 0,
                                                                 componentFlagsMask: 0)

            var unit: AudioUnit?
            guard let audioComponent = AudioComponentFindNext(nil, &componentDescription) else { return nil }
            guard AudioComponentInstanceNew(audioComponent, &unit) == noErr, let createdUnit = unit else { return nil }

            // Set audio unit input/output stream format to processing format
            var format = processingFormat
            guard AudioUnitSetProperty(createdUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &format, UInt32(MemoryLayout<AudioStreamBasicDescription>.stride)) == noErr else { return nil }
            guard AudioUnitSetProperty(createdUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &format, UInt32(MemoryLayout<AudioStreamBasicDescription>.stride)) == noErr else { return nil }

            // Set audio unit render callback
            var renderCallback = AURenderCallbackStruct(inputProc: highPassFilterRenderCallback, inputProcRefCon: Unmanaged.passUnretained(self).toOpaque())
            guard AudioUnitSetProperty(createdUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, UInt32(MemoryLayout<AURenderCallbackStruct>.stride)) == noErr else { return nil }

            // Set audio unit maximum frames per slice to max frames
            var maximumFramesPerSlice = UInt32(maxFrames)
            guard AudioUnitSetProperty(createdUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, UInt32(MemoryLayout<UInt32>.stride)) == noErr else { return nil }

            // Initialize audio unit
            guard AudioUnitInitialize(createdUnit) == noErr else {
                AudioComponentInstanceDispose(createdUnit)
                return nil
            }

            AudioUnitSetParameter(createdUnit, kHipassParam_CutoffFrequency, kAudioUnitScope_Global, 0, 180, 0)
            AudioUnitSetParameter(createdUnit, kHipassParam_Resonance, kAudioUnitScope_Global, 0, 0, 0)

            return createdUnit
        }

        let highPassFilterRenderCallback: AURenderCallback = { inRefCon, _, inTimeStamp, _, inNumberFrames, ioData -> OSStatus in
            let referenceToSelf = unsafeBitCast(inRefCon, to: DefaultPlayer.self)
            guard let peakLimiter = referenceToSelf.peakLimiter, let ioData = ioData else { return -1 }

            var audioTimeStamp = AudioTimeStamp()
            audioTimeStamp.mSampleTime = inTimeStamp.pointee.mSampleTime
            audioTimeStamp.mFlags = AudioTimeStampFlags.sampleTimeValid

            // The high pass filter calls the peak limiter as the next thing in the chain
            var actionFlags = AudioUnitRenderActionFlags()
            return AudioUnitRender(peakLimiter, &actionFlags, &audioTimeStamp, 0, inNumberFrames, ioData)
        }
    #endif

    // MARK: - Helpers

    private func performSetPlaybackRate() {
        if requiredPlaybackRate < 0.5 {
            requiredPlaybackRate = 1.0
        }

        player?.rate = Float(requiredPlaybackRate)

        player?.currentItem?.audioTimePitchAlgorithm = .timeDomain
    }

    private func jumpToStartingPosition() {
        let startingTime = PlaybackManager.shared.requiredStartingPosition()

        // there's a bug that when playing over AirPlay to a HomePod, seeking in stream that's already where you are up to sometimes doesn't work, this is a weird workaround for that case
        // https://github.com/shiftyjelly/pocketcasts-ios/issues/1936 is worth a read if you ever come here thinking you want to change this code
        if round(startingTime) != round(currentTime()) {
            seekTo(startingTime, completion: nil)
        }

        PlaybackManager.shared.playerDidFinishPreparing()
    }

    private func startBackgroundTask() {
        #if !os(watchOS)
            guard backgroundTaskId == .invalid else { return } // already started

            backgroundTaskId = UIApplication.shared.beginBackgroundTask(expirationHandler: { [weak self] in
                self?.endBackgroundTask()
            })

            // schedule a timer to cancel the background task as soon as bufferring is done or we don't need to play anymore
            // do this on the main thread because timers require run loops
            DispatchQueue.main.async {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                    guard let self = self else {
                        timer.invalidate()
                        return
                    }

                    if !self.buffering() || !self.shouldKeepPlaying {
                        self.endBackgroundTask()
                        timer.invalidate()
                    }
                }
            }
        #endif
    }

    private func endBackgroundTask() {
        #if !os(watchOS)
            if backgroundTaskId == .invalid { return } // already cancelled

            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        #endif
    }

    // MARK: - Error Handling

    private func handlePlaybackError(_ message: String) {
        // only reports errors if we're meant to be playing
        if shouldKeepPlaying {
            shouldKeepPlaying = false
            PlaybackManager.shared.playbackDidFail(logMessage: message, userMessage: nil)
        }
    }

    // MARK: - Player Setup/Cleanup

    private func configurePlayer(videoPodcast: Bool) {
        #if !os(watchOS)
            player?.allowsExternalPlayback = videoPodcast
        #endif

        durationObserver = player?.currentItem?.observe(\.duration) { _, _ in
            PlaybackManager.shared.playerDidCalculateDuration()
        }

        // Listen for changes to the timeControlStatus to determine if the system has decided to pause the playback
        // and if we need to try playing again. This seems to only happen when streaming on AirPlay for some reason.
        //
        // This should fix: https://github.com/Automattic/pocket-casts-ios/issues/47
        timeControlStatusObserver = player?.observe(\.timeControlStatus) { [weak self] player, _ in
            #if !os(watchOS)
            // We're going to be very explicit about the trigger for this to prevent triggering it when we don't want to

            // Only apply the logic when playing over AirPlay
            guard PlaybackManager.shared.playingOverAirplay(), let self else { return }

            // We'll keep track of the previous statuses and compare against them in the check below
            defer {
                self.previousReasonForWaiting = player.reasonForWaitingToPlay
                self.previousTimeControlStatus = player.timeControlStatus
            }

            guard
                // Verify that we indeed want to keep playing, ie: the user hasn't manually paused
                // And that we're waiting for the initial playback to begin
                self.shouldKeepPlaying, self.isWaitingForInitialPlayback,
                // Verify playback has stopped now, but we were waiting to play the audio
                player.timeControlStatus == .paused, self.previousTimeControlStatus == .waitingToPlayAtSpecifiedRate,
                // Verify that while we were waiting to play the reason switched to no item to play, and that currently there is no current reason
                player.reasonForWaitingToPlay == nil, self.previousReasonForWaiting == .noItemToPlay
            else {
                return
            }

            FileLog.shared.addMessage("[DefaultPlayer] Detected that playback was paused while trying to play the next item. Attempting to resume playback...")
            self.play()
            #endif
        }

        rateObserver = player?.observe(\.rate) { [weak self] player, _ in
            guard let self = self else { return }

            if player.rate == 1 {
                // there's a bug where playback can be resumed from outside our app, and Apple sets the wrong playback rate, fix that here
                // the easiest way to repeat this is to play a video at 2x, and press pause once it's in picture in picture mode
                let requiredSpeed = PlaybackManager.shared.effects().playbackSpeed
                if requiredSpeed != 1 {
                    self.performSetPlaybackRate()
                }
            }

            if let lastBackgroundedDate = self.lastBackgroundedDate {
                let timeintervalSinceBackground = fabs(lastBackgroundedDate.timeIntervalSinceNow)
                // we were backgrounded in the last 2 seconds, then the rate has changed, sounds like iOS is pausing video
                if player.rate <= 0, self.shouldKeepPlaying, timeintervalSinceBackground > 0, timeintervalSinceBackground < 2 {
                    FileLog.shared.addMessage("Playback was paused by iOS, but it looks like we're still meant to be playing, calling play")
                    self.play(completion: nil)
                }
            }

            PlaybackManager.shared.playerDidChangeNowPlayingInfo()
        }

        playerStatusObserver = player?.observe(\.status) { [weak self] _, _ in
            self?.playerStatusDidChange()
        }
        playerItemStatusObserver = player?.currentItem?.observe(\.status) { [weak self] _, _ in
            self?.playerStatusDidChange()
        }

        let nc = NotificationCenter.default
        playToEndObserver = nc.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }

            self.shouldKeepPlaying = false

            if let itemThatFinished = notification.object as? AVPlayerItem {
                let duration = CMTimeGetSeconds(itemThatFinished.duration)
                let upTo = CMTimeGetSeconds(itemThatFinished.currentTime())
                if duration > upTo + (duration * 0.05) {
                    FileLog.shared.addMessage("Item didn't actually finish got to \(upTo) of \(duration)")
                    return
                }
            }

            PlaybackManager.shared.playerDidFinishPlayingEpisode()
        }

        playFailedObserver = nc.addObserver(forName: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }

            self.shouldKeepPlaying = false

            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            let errorMessage = error?.localizedDescription ?? "Unknown item did fail to finish error"
            PlaybackManager.shared.playbackDidFail(logMessage: errorMessage, userMessage: nil)
        }

        _ = nc.addObserver(forName: NSNotification.Name.AVPlayerItemPlaybackStalled, object: nil, queue: nil) { [weak self] _ in
            guard let self = self else { return }

            if self.shouldKeepPlaying {
                self.play(completion: nil)
            }
        }
    }

    private func cleanupPlayer() {
        player?.currentItem?.audioMix = nil
        durationObserver = nil
        rateObserver = nil
        playerStatusObserver = nil
        playerItemStatusObserver = nil
        timeControlStatusObserver = nil

        if let endObserver = playToEndObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        if let failedObserver = playFailedObserver {
            NotificationCenter.default.removeObserver(failedObserver)
        }
        if let stalledObserver = playStalledObserver {
            NotificationCenter.default.removeObserver(stalledObserver)
        }

        playToEndObserver = nil
        playFailedObserver = nil
        playStalledObserver = nil

        endBackgroundTask()
    }

    // MARK: Hashable

    static func == (lhs: DefaultPlayer, rhs: DefaultPlayer) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    func loadEmbeddedImage() {
        #if !os(watchOS)
        guard let asset = player?.currentItem?.asset, let episodeUuid, let podcastUuid else {
            return
        }

        episodeArtwork.loadEmbeddedImage(asset: asset, podcastUuid: podcastUuid, episodeUuid: episodeUuid)
        #endif
    }

    // MARK: - Volume

    func setVolume(_ volume: Float) {
        
    }
}
