import AVFoundation
import PocketCastsDataModel
import PocketCastsUtils

class AudioPlayTask {
    private static let minFramesToSchedule = 10 as Int32

    private var player: AVAudioPlayerNode
    private var bufferManager: PlayBufferManager

    private let cancelled = AtomicBool()

    private let audioQueue: DispatchQueue
    private let updateQueue: DispatchQueue

    private var lastFramePlayed: AVAudioFramePosition?
    private var framesScheduled = 0 as Int32
    private var lastTimeFrameScheduled = 0 as TimeInterval

    private let queueingSemaphone = DispatchSemaphore(value: 0)

    init(player: AVAudioPlayerNode, bufferManager: PlayBufferManager) {
        updateQueue = DispatchQueue(label: "au.com.pocketcasts.PlayVariablesQueue")
        audioQueue = DispatchQueue(label: "au.com.pocketcasts.AudioPlayQueue", qos: DispatchQoS(qosClass: .userInitiated, relativePriority: 0), attributes: [], autoreleaseFrequency: .never, target: nil)

        self.player = player
        self.bufferManager = bufferManager
    }

    func startup() {
        audioQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            // call this once to immediately skip the 1st wait below
            strongSelf.queueingSemaphone.signal()

            while !strongSelf.cancelled.value {
                strongSelf.queueingSemaphone.wait()

                if !strongSelf.cancelled.value {
                    strongSelf.scheduleNextBuffer()
                    if strongSelf.bufferManager.bufferLength() <= strongSelf.bufferManager.lowBufferPoint {
                        strongSelf.bufferManager.bufferSemaphore.signal()
                    }
                }
            }
        }
    }

    func shutdown() {
        cancelled.value = true
        queueingSemaphone.signal() // the read task is probably waiting on more data, so fire this off to let it know we're done
    }

    func lastFrameRendered() -> AVAudioFramePosition? {
        updateQueue.sync {
            lastFramePlayed
        }
    }

    private func scheduleNextBuffer() {
        while !cancelled.value, bufferManager.bufferLength() == 0 {
            // if the read thread has gotten to the end of the file and we haven't scheduled anything in the last second, playback is done
            if bufferManager.readToEOFSuccessfully.value, Date().timeIntervalSince1970 > (lastTimeFrameScheduled + 1) {
                if !bufferManager.haveNotifiedPlayer.value {
                    bufferManager.haveNotifiedPlayer.value = true

                    FileLog.shared.addMessage("EffectsPlayer got to end of episode, calling finished playing")
                    PlaybackManager.shared.playerDidFinishPlayingEpisode()
                }
                shutdown()

                return
            }

            if bufferManager.readErrorOccurred.value {
                PlaybackManager.shared.playbackDidFail(logMessage: "Buffer read error occurred", userMessage: nil)
                shutdown()

                return
            }

            // sleep while we have no buffers to play
            Thread.sleep(forTimeInterval: 0.025)
        }

        if let nextBuffer = bufferManager.pop() {
            if nextBuffer.shouldFadeOut || nextBuffer.shouldFadeIn {
                let channelCount = nextBuffer.audioBuffer.audioBufferList.pointee.mNumberBuffers
                AudioUtils.fadeAudio(nextBuffer, fadeOut: nextBuffer.shouldFadeOut, channelCount: channelCount)
            }

            updateQueue.sync {
                framesScheduled += 1
                lastFramePlayed = nextBuffer.framePosition

                // if we haven't scheduled enough frames yet signal an extra time each time through this loop until we have
                if framesScheduled < AudioPlayTask.minFramesToSchedule {
                    queueingSemaphone.signal()
                }
            }

            lastTimeFrameScheduled = Date().timeIntervalSince1970
            player.scheduleBuffer(nextBuffer.audioBuffer, completionHandler: { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.updateQueue.sync { strongSelf.framesScheduled -= 1 }
                strongSelf.queueingSemaphone.signal()
            })
        }
    }
}
