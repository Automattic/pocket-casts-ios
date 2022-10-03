import AVFoundation
import Foundation

class SynchronizedAudioStack {
    private var itemQueue = Queue<BufferedAudio>()
    private var itemQueueCount = 0
    private var samplesStored = 0 as AVAudioFrameCount

    private let singleQueue = DispatchQueue(label: "au.com.pocketcasts.SynchronizedAudioStackQueue")

    func push(_ item: BufferedAudio) {
        singleQueue.sync {
            itemQueue.enqueue(item)
            itemQueueCount += 1
            samplesStored += item.audioBuffer.frameLength
        }
    }

    func pop() -> BufferedAudio? {
        singleQueue.sync {
            if let item = itemQueue.dequeue() {
                itemQueueCount -= 1
                samplesStored -= item.audioBuffer.frameLength

                return item
            }

            return nil
        }
    }

    func removeAll() {
        singleQueue.sync {
            itemQueue.removeAll()
            itemQueueCount = 0
            samplesStored = 0
        }
    }

    func canPop() -> Bool {
        singleQueue.sync {
            !itemQueue.isEmpty
        }
    }

    func count() -> Int {
        singleQueue.sync {
            itemQueueCount
        }
    }

    func sampleCount() -> Int64 {
        singleQueue.sync {
            Int64(samplesStored)
        }
    }

    func averageSampleCount() -> AVAudioFrameCount {
        singleQueue.sync {
            if itemQueueCount == 0 || samplesStored == 0 { return 0 }

            return samplesStored / UInt32(itemQueueCount)
        }
    }
}
