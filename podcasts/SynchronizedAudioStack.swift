import AVFoundation
import Foundation
import PocketCastsUtils

class SynchronizedAudioStack {
    private struct State {
        var itemQueue = Queue<BufferedAudio>()
        var itemQueueCount = 0
        var samplesStored = 0 as AVAudioFrameCount
    }

    private let state = Mutex(State())

    func push(_ item: BufferedAudio) {
        state.withLock { state in
            state.itemQueue.enqueue(item)
            state.itemQueueCount += 1
            state.samplesStored += item.audioBuffer.frameLength
        }
    }

    func pop() -> BufferedAudio? {
        state.withLock { state in
            if let item = state.itemQueue.dequeue() {
                state.itemQueueCount -= 1
                state.samplesStored -= item.audioBuffer.frameLength

                return item
            }

            return nil
        }
    }

    func removeAll() {
        state.withLock { state in
            state.itemQueue.removeAll()
            state.itemQueueCount = 0
            state.samplesStored = 0
        }
    }

    func canPop() -> Bool {
        state.withLock { state in
            !state.itemQueue.isEmpty
        }
    }

    func count() -> Int {
        state.withLock { state in
            state.itemQueueCount
        }
    }

    func averageSampleCount() -> AVAudioFrameCount {
        state.withLock { state in
            if state.itemQueueCount == 0 || state.samplesStored == 0 { return 0 }

            return state.samplesStored / UInt32(state.itemQueueCount)
        }
    }
}
