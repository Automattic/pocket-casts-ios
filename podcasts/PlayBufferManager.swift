import AVFoundation
import Foundation
import PocketCastsUtils

class PlayBufferManager {
    private var playBuffer = SynchronizedAudioStack()

    let lowBufferPoint = 300
    let highBufferPoint = 3000 // this equates to roughly a minute of audio
    let bufferSemaphore = DispatchSemaphore(value: 0)

    var readToEOFSuccessfully = AtomicBool()
    var readErrorOccurred = AtomicBool()
    var haveNotifiedPlayer = AtomicBool()

    func aboutToSeek() {
        let itemThatWouldHavePlayedNext = playBuffer.pop()
        removeAll()
        // if possible, leave the next item that would have played on the buffer, so we can fade it out
        if var item = itemThatWouldHavePlayedNext {
            item.shouldFadeOut = true
            playBuffer.push(item)
        }
    }

    func push(_ item: BufferedAudio) {
        playBuffer.push(item)
    }

    func pop() -> BufferedAudio? {
        playBuffer.pop()
    }

    func removeAll() {
        playBuffer.removeAll()
    }

    func canPop() -> Bool {
        playBuffer.canPop()
    }

    func bufferLength() -> Int {
        playBuffer.count()
    }

    func samplesBuffered() -> Int64 {
        playBuffer.sampleCount()
    }

    func averageSampleCount() -> AVAudioFrameCount {
        playBuffer.averageSampleCount()
    }
}
