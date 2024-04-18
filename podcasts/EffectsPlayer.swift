import AudioUnit
import AVFoundation
import PocketCastsDataModel
import PocketCastsUtils
import UIKit

enum EffectsPlayerStrategy: Int {
    case normalPlay = 1
    case playAndCatchExceptionIfNeeded = 2
    case playAndFallbackIfNeeded = 3
}

class EffectsPlayer: PlaybackProtocol, Hashable {
    private static let targetVolumeDbGain = 15.0 as Float

    /// The maximum number this player will retry to restard an audio if it fails
    private static let maxNumberOfRetries = 3

    /// The current attempt number to start the player
    private static var attemptNumber = 1

    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?

    private var timePitch: AVAudioUnitTimePitch?
    private var playbackSpeed = 0 as Double // AVAudioUnitTimePitch seems to not like us querying the rate sometimes, so store that as a separate variable

    // for volume boost
    private var highPassFilter: AVAudioUnitEffect?
    private var dynamicsProcessor: AVAudioUnitEffect?
    private var peakLimiter: AVAudioUnitEffect?

    private var playBufferManager: PlayBufferManager?
    private var audioReadTask: AudioReadTask?
    private var audioPlayTask: AudioPlayTask?
    private var audioFile: AVAudioFile?

    private var effects = PlaybackEffects()

    private let shouldKeepPlaying = AtomicBool()
    private var haveFiredDurationNotification = false

    private let aboutToPlay = AtomicBool()
    private var episodePath: String?
    private var episode: BaseEpisode?
    private var cachedFrameCount = 0 as Int64

    private var seeking = false
    private var lastSeekTime = 0 as TimeInterval

    // this lock is to avoid race conditions where you're destroying the player while in the middle of setting it up (since the play method does its work asynchronously)
    private lazy var playerLock = NSLock()

    private lazy var episodeArtwork = EpisodeArtwork()

    // MARK: - PlaybackProtocol Impl

    func loadEpisode(_ episode: BaseEpisode) {
        episodePath = episode.pathToDownloadedFile(pathFinder: DownloadManager.shared)
        episodeArtwork.loadEmbeddedImage(asset: nil, podcastUuid: episode.parentIdentifier(), episodeUuid: episode.uuid)
        self.episode = episode
    }

    func playing() -> Bool {
        if aboutToPlay.value { return true }

        if let player = player {
            return player.isPlaying
        }

        return false
    }

    func play(completion: (() -> Void)?) {
        aboutToPlay.value = true
        shouldKeepPlaying.value = true

        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self, let episode = strongSelf.episode else { return }

            strongSelf.playerLock.lock()

            strongSelf.engine = AVAudioEngine()
            strongSelf.player = AVAudioPlayerNode()
            strongSelf.engine?.attach(strongSelf.player!)

            strongSelf.effects = PlaybackManager.shared.effects()
            strongSelf.playBufferManager = PlayBufferManager()

            // volume boost effects
            strongSelf.highPassFilter = strongSelf.createHighPassUnit()
            strongSelf.engine?.attach(strongSelf.highPassFilter!)

            strongSelf.dynamicsProcessor = strongSelf.createDynamicsProcessorUnit()
            strongSelf.engine?.attach(strongSelf.dynamicsProcessor!)

            strongSelf.peakLimiter = strongSelf.createPeakLimiterUnit()
            strongSelf.engine?.attach(strongSelf.peakLimiter!)
            strongSelf.setVolumeBoostSettings()

            strongSelf.timePitch = strongSelf.createTimePitchUnit()
            strongSelf.playbackSpeed = 1.0
            strongSelf.timePitch?.rate = 1.0
            strongSelf.engine?.attach(strongSelf.timePitch!)

            let fileURL = URL(fileURLWithPath: strongSelf.episodePath!)
            do {
                strongSelf.audioFile = try AVAudioFile(forReading: fileURL, commonFormat: AVAudioCommonFormat.pcmFormatFloat32, interleaved: false)

                // AVAudioFile.length is an expensive operation (often in the seconds) so here we attempt to load a cached value instead
                strongSelf.cachedFrameCount = DataManager.sharedManager.findFrameCount(episode: episode)
                if strongSelf.cachedFrameCount == 0 {
                    // we haven't cached a frame count for this episode, do that now
                    strongSelf.cachedFrameCount = strongSelf.audioFile!.length
                    DataManager.sharedManager.saveFrameCount(episode: episode, frameCount: strongSelf.cachedFrameCount)
                }
            } catch {
                strongSelf.playerLock.unlock()
                PlaybackManager.shared.playbackDidFail(logMessage: error.localizedDescription, userMessage: nil)
                return
            }

            // iOS 16 has an issue in which if the conditions below are met, the playback will fail:
            // Audio file has a single channel and spatial audio is enabled
            // In order to prevent this issue, we create a two channel format and inside
            // `AudioReadTask` we convert the mono segments to stereo
            // For more info, see: https://github.com/Automattic/pocket-casts-ios/issues/62
            var format: AVAudioFormat
            if #available(iOS 16, *),
               let audioFile = strongSelf.audioFile,
               audioFile.processingFormat.channelCount == 1,
               let twoChannelsFormat = AVAudioFormat(standardFormatWithSampleRate: audioFile.processingFormat.sampleRate, channels: 2) {
                FileLog.shared.addMessage("EffectsPlayer: converting mono to stereo")
                format = twoChannelsFormat
            } else {
                format = strongSelf.audioFile!.processingFormat
            }

            strongSelf.engine?.connect(strongSelf.player!, to: strongSelf.timePitch!, format: format)
            strongSelf.engine?.connect(strongSelf.timePitch!, to: strongSelf.highPassFilter!, format: format)
            strongSelf.engine?.connect(strongSelf.highPassFilter!, to: strongSelf.dynamicsProcessor!, format: format)
            strongSelf.engine?.connect(strongSelf.dynamicsProcessor!, to: strongSelf.peakLimiter!, format: format)
            strongSelf.engine?.connect(strongSelf.peakLimiter!, to: strongSelf.engine!.outputNode, format: format)

            strongSelf.startReadAndPlayThreads()
            do {
                strongSelf.engine?.prepare()
                try strongSelf.engine?.start()
            } catch {
                strongSelf.playerLock.unlock()
                PlaybackManager.shared.playbackDidFail(logMessage: error.localizedDescription, userMessage: nil)
                return
            }
            // there seem to be cases where the above call succeeds but the engine isn't actually started. Handle that here
            if !(strongSelf.engine?.isRunning ?? false) {
                strongSelf.playerLock.unlock()
                FileLog.shared.addMessage("EffectsPlayer: engine reported not running, calling playbackDidFail")
                PlaybackManager.shared.playbackDidFail(logMessage: "AVAudioEngine reported not running", userMessage: nil)
                return
            }

            switch Settings.effectsPlayerStrategy {
            case .normalPlay:
                strongSelf.normalPlay()
            case .playAndCatchExceptionIfNeeded:
                strongSelf.playAndCatchExceptionIfNeeded()
            case .playAndFallbackIfNeeded:
                strongSelf.playAndFallbackIfNeeded()
            default:
                strongSelf.normalPlay()
            }

            strongSelf.playerLock.unlock()

            completion?()

            if strongSelf.haveFiredDurationNotification == false {
                strongSelf.haveFiredDurationNotification = true

                PlaybackManager.shared.playerDidCalculateDuration()
            }

            self?.aboutToPlay.value = false
        }
    }

    // MARK: - Play
    /// We have three ways to start the player here. This is here to try
    /// to fix one of our top-crashes which is related to EffectsPlayer initialization

    /// Just play the player and don't deal with any exception
    func normalPlay() {
        player?.play()
    }

    /// Try to play. If an exception happens, just pause it.
    func playAndCatchExceptionIfNeeded() {
        do {
            try SJCommonUtils.catchException {
                self.player?.play()
            }
        } catch {
            FileLog.shared.addMessage("EffectsPlayer: failed to start playback: \(error)")
            self.playerLock.unlock()
            PlaybackManager.shared.pause(userInitiated: false)
        }
    }

    /// Try to play. If it fails, fallback to DefaultPlayer
    func playAndFallbackIfNeeded() {
        do {
            try SJCommonUtils.catchException {
                self.player?.play()
            }
        } catch {
            self.playerLock.unlock()
            PlaybackManager.shared.playbackDidFail(logMessage: error.localizedDescription, userMessage: nil, fallbackToDefaultPlayer: true)
        }
    }

    func pause() {
        shouldKeepPlaying.value = false
        aboutToPlay.value = false

        PlaybackManager.shared.playerDidRequestTermination()
    }

    func playbackRate() -> Double {
        playbackSpeed
    }

    func setPlaybackRate(_ rate: Double) {
        if let timePitch = timePitch {
            playbackSpeed = rate
            timePitch.rate = Float(rate)
        }
    }

    func seekTo(_ time: TimeInterval, completion: (() -> Void)?) {
        guard let readOperation = audioReadTask else { return }

        lastSeekTime = max(0.1, time)
        seeking = true
        readOperation.seekTo(time, completion: { [weak self] seekedToEnd in
            if !seekedToEnd {
                completion?()
            } else if !(self?.playBufferManager?.haveNotifiedPlayer.value ?? false) {
                self?.playBufferManager?.haveNotifiedPlayer.value = true
                FileLog.shared.addMessage("EffectsPlayer seeked passed end of episode, calling finished playing")
                PlaybackManager.shared.playerDidFinishPlayingEpisode()
            }

            self?.seeking = false
        })
    }

    func currentTime() -> TimeInterval {
        if seeking {
            return lastSeekTime
        }

        if let audioFile = audioFile, let curFrame = currentFrame() {
            return Double(curFrame) / audioFile.fileFormat.sampleRate
        }

        return -1
    }

    private func currentFrame() -> AVAudioFramePosition? {
        if let audioPlayTask = audioPlayTask {
            return audioPlayTask.lastFrameRendered()
        }

        return nil
    }

    func duration() -> TimeInterval {
        if let audioFile = audioFile {
            return (Double(cachedFrameCount) / audioFile.fileFormat.sampleRate)
        }

        return -1
    }

    func effectsDidChange() {
        effects = PlaybackManager.shared.effects()

        audioReadTask?.setTrimSilence(effects.trimSilence)
        playbackSpeed = effects.playbackSpeed
        timePitch?.rate = Float(playbackSpeed)

        setVolumeBoostSettings()
    }

    func endPlayback(permanent: Bool) {
        playerLock.lock()
        defer { playerLock.unlock() }

        shouldKeepPlaying.value = false
        aboutToPlay.value = false

        audioReadTask?.shutdown()
        audioPlayTask?.shutdown()
        playBufferManager?.removeAll()

        if playing() {
            player?.pause()
        }

        player?.stop()

        engine?.stop()
    }

    func supportsSilenceRemoval() -> Bool {
        true
    }

    func supportsVolumeBoost() -> Bool {
        true
    }

    func supportsGoogleCast() -> Bool {
        false
    }

    func supportsStreaming() -> Bool {
        false
    }

    func supportsAirplay2() -> Bool {
        false
    }

    // we only ever play downloaded content, so we're never buffering or worry about future buffer
    func buffering() -> Bool {
        false
    }

    func futureBufferAvailable() -> TimeInterval {
        duration() - currentTime()
    }

    func shouldBePlaying() -> Bool {
        shouldKeepPlaying.value
    }

    func internalPlayerForVideoPlayback() -> AVPlayer? {
        nil
    }

    // MARK: - Handle interruptions

    func interruptionDidStart() {
        // AVAudioEngine doesn't handle interruptions as natively as AVPlayer, so we pause manually here to spin things down
        pause()
    }

    func routeDidChange(shouldPause: Bool) {
        shouldKeepPlaying.value = shouldKeepPlaying.value && !shouldPause

        // when this is called, the engine has detected an interruption like a route change. Because this happens on things like bluetooth connect, and not just disconnect, we deal with it here.
        // The audio engine has shut down at this point, so we call pause to destroy all our current state and play to restore it all if we should still be playing
        if shouldKeepPlaying.value, !PlaybackManager.shared.interruptionInProgress() {
            PlaybackManager.shared.pause(userInitiated: false)
            PlaybackManager.shared.play(userInitiated: false)
        } else if !shouldKeepPlaying.value {
            PlaybackManager.shared.pause(userInitiated: false)
        }
    }

    // MARK: - Helper methods

    private func startReadAndPlayThreads() {
        // just in case there are any running
        audioReadTask?.shutdown()
        audioPlayTask?.shutdown()

        guard let audioFile = audioFile, let player = player, let playBufferManager = playBufferManager else { return }
        let requiredStartTime = PlaybackManager.shared.requiredStartingPosition()
        audioReadTask = AudioReadTask(trimSilence: effects.trimSilence, audioFile: audioFile, outputFormat: audioFile.processingFormat, bufferManager: playBufferManager, playPositionHint: requiredStartTime, frameCount: cachedFrameCount)
        audioPlayTask = AudioPlayTask(player: player, bufferManager: playBufferManager)

        audioReadTask?.startup()
        audioPlayTask?.startup()

        PlaybackManager.shared.playerDidFinishPreparing()
    }

    private func setVolumeBoostSettings() {
        if !effects.volumeBoost {
            peakLimiter?.bypass = true
            highPassFilter?.bypass = true
            dynamicsProcessor?.bypass = true
        } else {
            setFloatParameter(highPassFilter?.audioUnit, key: kHipassParam_CutoffFrequency, value: 180)
            setFloatParameter(highPassFilter?.audioUnit, key: kHipassParam_Resonance, value: 0)
            highPassFilter?.bypass = false

            setFloatParameter(dynamicsProcessor?.audioUnit, key: kDynamicsProcessorParam_Threshold, value: -41)
            setFloatParameter(dynamicsProcessor?.audioUnit, key: kDynamicsProcessorParam_HeadRoom, value: 40)
            setFloatParameter(dynamicsProcessor?.audioUnit, key: kDynamicsProcessorParam_ExpansionRatio, value: 1)
            setFloatParameter(dynamicsProcessor?.audioUnit, key: kDynamicsProcessorParam_ExpansionThreshold, value: -100)
            setFloatParameter(dynamicsProcessor?.audioUnit, key: kDynamicsProcessorParam_AttackTime, value: 0.05)
            setFloatParameter(dynamicsProcessor?.audioUnit, key: kDynamicsProcessorParam_ReleaseTime, value: 0.2)

            // This variable was renamed in Xcode 13, iOS 15. Include this check so it still compiles in Xcode 12
            #if swift(<5.5)
                setFloatParameter(dynamicsProcessor?.audioUnit, key: kDynamicsProcessorParam_MasterGain, value: 0)
            #else
                setFloatParameter(dynamicsProcessor?.audioUnit, key: kDynamicsProcessorParam_OverallGain, value: 0)
            #endif

            setFloatParameter(dynamicsProcessor?.audioUnit, key: kDynamicsProcessorParam_CompressionAmount, value: 0)
            setFloatParameter(dynamicsProcessor?.audioUnit, key: kDynamicsProcessorParam_InputAmplitude, value: -120)
            setFloatParameter(dynamicsProcessor?.audioUnit, key: kDynamicsProcessorParam_OutputAmplitude, value: -120)
            dynamicsProcessor?.bypass = false

            setFloatParameter(peakLimiter?.audioUnit, key: kLimiterParam_AttackTime, value: 0.002)
            setFloatParameter(peakLimiter?.audioUnit, key: kLimiterParam_DecayTime, value: 0.005)
            setFloatParameter(peakLimiter?.audioUnit, key: kLimiterParam_PreGain, value: 11)
            peakLimiter?.bypass = false
        }
    }

    // MARK: - Audio Units

    private func setFloatParameter(_ audioUnit: AudioUnit?, key: AudioUnitParameterID, value: Float) {
        if let audioUnit = audioUnit {
            AudioUnitSetParameter(audioUnit, key, kAudioUnitScope_Global, 0, value, 0)
        }
    }

    private func createTimePitchUnit() -> AVAudioUnitTimePitch {
        var componentDescription = AudioComponentDescription()
        componentDescription.componentType = kAudioUnitType_FormatConverter
        componentDescription.componentSubType = kAudioUnitSubType_AUiPodTimeOther
        componentDescription.componentManufacturer = kAudioUnitManufacturer_Apple

        return AVAudioUnitTimePitch(audioComponentDescription: componentDescription)
    }

    private func createHighPassUnit() -> AVAudioUnitEffect {
        var componentDescription = AudioComponentDescription()
        componentDescription.componentType = kAudioUnitType_Effect
        componentDescription.componentSubType = kAudioUnitSubType_HighPassFilter
        componentDescription.componentManufacturer = kAudioUnitManufacturer_Apple

        return AVAudioUnitEffect(audioComponentDescription: componentDescription)
    }

    private func createDynamicsProcessorUnit() -> AVAudioUnitEffect {
        var componentDescription = AudioComponentDescription()
        componentDescription.componentType = kAudioUnitType_Effect
        componentDescription.componentSubType = kAudioUnitSubType_DynamicsProcessor
        componentDescription.componentManufacturer = kAudioUnitManufacturer_Apple

        return AVAudioUnitEffect(audioComponentDescription: componentDescription)
    }

    private func createPeakLimiterUnit() -> AVAudioUnitEffect {
        var componentDescription = AudioComponentDescription()
        componentDescription.componentType = kAudioUnitType_Effect
        componentDescription.componentSubType = kAudioUnitSubType_PeakLimiter
        componentDescription.componentManufacturer = kAudioUnitManufacturer_Apple

        return AVAudioUnitEffect(audioComponentDescription: componentDescription)
    }

    // MARK: Hashable

    static func == (lhs: EffectsPlayer, rhs: EffectsPlayer) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    // MARK: - Volume

    func setVolume(_ volume: Float) {
        
    }
}
