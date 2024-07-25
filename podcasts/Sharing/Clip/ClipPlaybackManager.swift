import AVFoundation
import PocketCastsDataModel
import Combine
import SwiftUI

class ClipPlaybackManager: ObservableObject {

    static var shared = ClipPlaybackManager()

    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval?
    @Published var duration: TimeInterval = 0

    private var startTime: TimeInterval = 0
    private var endTime: TimeInterval = 0

    private var avPlayer: AVPlayer?
    private var timeObserverToken: Any?
    private var cancellables = Set<AnyCancellable>()

    @ObservedObject var clipTime: ClipTime = ClipTime(start: 0, end: 0)

    func play(episode: BaseEpisode, clipTime: ObservedObject<ClipTime>) {
        if avPlayer != nil {
            stop()
            avPlayer = nil
        }

        PlaybackManager.shared.pause()

        //TODO: Check the Player's current episode and reuse the player item
        guard let playerItem = DownloadManager.shared.downloadParallelToStream(of: episode) else {
//            handlePlaybackError("Unable to create playback item")
            return
        }

        avPlayer = AVPlayer(playerItem: playerItem)

        let startTime = clipTime.projectedValue.start.wrappedValue
        let endTime = clipTime.projectedValue.end.wrappedValue

        let startCMTime = CMTime(seconds: startTime, preferredTimescale: 600)
        let endCMTime = CMTime(seconds: endTime, preferredTimescale: 600)

        PlaybackManager.shared.activateAudioSession(completion: { [weak self] activated in
            self?.avPlayer?.currentItem?.forwardPlaybackEndTime = endCMTime

            self?.avPlayer?.seek(to: startCMTime)
            self?.avPlayer?.play()
        })

        isPlaying = true
        self.startTime = startTime
        self.endTime = endTime
        duration = endTime - startTime

        setupTimeObserver()
        observePlaybackEnd()

        self._clipTime = clipTime

        self.clipTime.$start.sink(receiveValue: { start in
            self.startTime = start
        }).store(in: &cancellables)

        self.clipTime.$end.sink(receiveValue: { end in
            self.endTime = end
        }).store(in: &cancellables)

        $currentTime.sink(receiveValue: { currentTime in
//            if let currentTime, currentTime != self?.avPlayer?.currentTime().seconds {
//                self?.avPlayer?.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
//            }
            if let currentTime, currentTime > 0 {
                clipTime.wrappedValue.playback = currentTime
            }
        }).store(in: &cancellables)
    }

    func seek(to time: CMTime) {
        avPlayer?.seek(to: time)
    }

    func stop() {
        avPlayer?.pause()
        isPlaying = false
        currentTime = 0
        duration = 0
        removeTimeObserver()
    }

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else {
                return
            }
            // Loops back to the beginning at end of clip range
            guard time.seconds < self.endTime else {
                self.avPlayer?.seek(to: CMTime(seconds: startTime, preferredTimescale: 600))
                return
            }
            self.currentTime = time.seconds
        }
    }

    private func removeTimeObserver() {
        if let token = timeObserverToken {
            avPlayer?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    private func observePlaybackEnd() {
        avPlayer?.publisher(for: \.timeControlStatus)
            .sink { [weak self] status in
                if status == .paused {
//                    self?.stop()
                }
            }
            .store(in: &cancellables)
    }
}
