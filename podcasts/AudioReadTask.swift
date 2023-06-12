import AVFoundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class AudioReadTask {
    private let maxSilenceAmountToSave = 1000

    private var minRMS = 0.005 as Float32
    private var minGapSizeInFrames = 3
    private var amountOfSilentFramesToReInsert = 1

    private let cancelled = AtomicBool()

    private let readQueue: DispatchQueue
    private let lock = NSObject()

    private var trimSilence: TrimSilenceAmount = .off

    private var audioFile: AVAudioFile
    private var outputFormat: AVAudioFormat
    private var bufferManager: PlayBufferManager

    private let bufferLength = UInt32(Constants.Audio.defaultFrameSize)
    private let bufferByteSize = Float32(MemoryLayout<Float32>.size)

    private var foundGap = false
    private var channelCount = 0 as UInt32
    private var buffersSavedDuringGap = SynchronizedAudioStack()
    private var fadeInNextFrame = true
    private var cachedFrameCount = 0 as Int64

    private var currentFramePosition: AVAudioFramePosition = 0
    private let endOfFileSemaphore = DispatchSemaphore(value: 0)

    init(trimSilence: TrimSilenceAmount, audioFile: AVAudioFile, outputFormat: AVAudioFormat, bufferManager: PlayBufferManager, playPositionHint: TimeInterval, frameCount: Int64) {
        self.trimSilence = trimSilence
        self.audioFile = audioFile
        self.outputFormat = outputFormat
        self.bufferManager = bufferManager
        cachedFrameCount = frameCount

        readQueue = DispatchQueue(label: "au.com.pocketcasts.ReadQueue", qos: .default, attributes: [], autoreleaseFrequency: .never, target: nil)

        updateRemoveSilenceNumbers()

        if playPositionHint > 0 {
            currentFramePosition = framePositionForTime(playPositionHint).framePosition
            audioFile.framePosition = currentFramePosition
        }
    }

    func startup() {
        readQueue.async { [weak self] in
            guard let self = self else { return }

            // there are some Core Audio errors that aren't marked as throws in the Swift code, so they'll crash the app
            // that's why we have an Objective-C try/catch block here to catch them (see https://github.com/shiftyjelly/pocketcasts-ios/issues/1493 for more details)
            do {
                try SJCommonUtils.catchException { [weak self] in
                    guard let self = self else { return }

                    do {
                        while !self.cancelled.value {
                            // nil is returned when there are playback errors or us getting to the end of a file, sleep so we don't end up in a tight loop but these all set the cancelled flag
                            guard let audioBuffers = try self.readFromFile() else {
                                Thread.sleep(forTimeInterval: 0.1)
                                continue
                            }

                            for buffer in audioBuffers {
                                self.scheduleForPlayback(buffer: buffer)
                            }
                        }
                    } catch {
                        self.bufferManager.readErrorOccurred.value = true
                        FileLog.shared.addMessage("Audio Read failed (Swift): \(error.localizedDescription)")
                    }
                }
            } catch {
                self.bufferManager.readErrorOccurred.value = true
                FileLog.shared.addMessage("Audio Read failed (obj-c): \(error.localizedDescription)")
            }
        }
    }

    func shutdown() {
        cancelled.value = true
        bufferManager.bufferSemaphore.signal()
        endOfFileSemaphore.signal()
    }

    func setTrimSilence(_ trimSilence: TrimSilenceAmount) {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }

        self.trimSilence = trimSilence
        updateRemoveSilenceNumbers()
    }

    private func updateRemoveSilenceNumbers() {
        guard trimSilence != .off else { return }

        minGapSizeInFrames = gapSizeForSilenceAmount()
        amountOfSilentFramesToReInsert = framesToReInsertForSilenceAmount()
        minRMS = minRMSForSilenceAmount()
    }

    func seekTo(_ time: TimeInterval, completion: ((Bool) -> Void)?) {
        DispatchQueue.global(qos: .default).async { () in
            let seekResult = self.performSeek(time)
            self.bufferManager.bufferSemaphore.signal()
            completion?(seekResult)
        }
    }

    private func performSeek(_ time: TimeInterval) -> Bool {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }

        let positionRequired = framePositionForTime(time)
        var seekedToEnd = false

        if positionRequired.passedEndOfFile {
            bufferManager.removeAll()
            bufferManager.readToEOFSuccessfully.value = true

            seekedToEnd = true
        } else {
            currentFramePosition = positionRequired.framePosition
            audioFile.framePosition = currentFramePosition
            bufferManager.aboutToSeek()
            foundGap = false
            buffersSavedDuringGap.removeAll()
            fadeInNextFrame = true

            // if we've finished reading this file, wake the reading thread back up
            if bufferManager.readToEOFSuccessfully.value {
                endOfFileSemaphore.signal()
            }
        }

        return seekedToEnd
    }

    private func handleReachedEndOfFile() {
        bufferManager.readToEOFSuccessfully.value = true

        // we've read to the end but the player won't yet have played to the end, wait til it signals us that it has
        endOfFileSemaphore.wait()
    }

    private func readFromFile() throws -> [BufferedAudio]? {
        objc_sync_enter(lock)

        // are we at the end of the file?
        currentFramePosition = audioFile.framePosition
        if currentFramePosition >= cachedFrameCount {
            objc_sync_exit(lock)
            handleReachedEndOfFile()

            return nil
        }

        let audioPCMBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: bufferLength)
        do {
            try audioFile.read(into: audioPCMBuffer!)
        } catch {
            objc_sync_exit(lock)
            throw PlaybackError.errorDuringPlayback
        }

        // check that we actually read something
        if audioPCMBuffer?.frameLength == 0 {
            objc_sync_exit(lock)
            handleReachedEndOfFile()

            return nil
        }

        currentFramePosition = audioFile.framePosition
        fadeInNextFrame = false
        if channelCount == 0 { channelCount = (audioPCMBuffer?.audioBufferList.pointee.mNumberBuffers)! }

        if channelCount == 0 {
            bufferManager.readErrorOccurred.value = true
            cancelled.value = true
            objc_sync_exit(lock)

            return nil
        }

        // iOS 16 has an issue in which if the conditions below are met, the playback will fail:
        // Audio file has a single channel and spatial audio is enabled
        // In order to prevent this issue, we convert a mono buffer to stereo buffer
        // For more info, see: https://github.com/Automattic/pocket-casts-ios/issues/62
        var audioBuffer: BufferedAudio
        if #available(iOS 16, *),
           let audioPCMBuffer = audioPCMBuffer,
           audioPCMBuffer.audioBufferList.pointee.mNumberBuffers == 1,
           let twoChannelsFormat = AVAudioFormat(standardFormatWithSampleRate: audioFile.processingFormat.sampleRate, channels: 2),
           let twoChannnelBuffer = AVAudioPCMBuffer(pcmFormat: twoChannelsFormat, frameCapacity: audioPCMBuffer.frameCapacity) {
            let converter = AVAudioConverter(from: audioFile.processingFormat, to: twoChannelsFormat)
            try? converter?.convert(to: twoChannnelBuffer, from: audioPCMBuffer)
            audioBuffer = BufferedAudio(audioBuffer: twoChannnelBuffer, framePosition: currentFramePosition, shouldFadeOut: false, shouldFadeIn: fadeInNextFrame)
        } else {
            audioBuffer = BufferedAudio(audioBuffer: audioPCMBuffer!, framePosition: currentFramePosition, shouldFadeOut: false, shouldFadeIn: fadeInNextFrame)
        }

        var buffers = [BufferedAudio]()
        if trimSilence != .off {
            guard let bufferListPointer = UnsafeMutableAudioBufferListPointer(audioPCMBuffer?.mutableAudioBufferList) else {
                buffers.append(audioBuffer)
                objc_sync_exit(lock)

                return buffers
            }

            let currPosition = currentFramePosition / Int64(audioFile.fileFormat.sampleRate)
            let totalDuration = cachedFrameCount / Int64(audioFile.fileFormat.sampleRate)
            let timeLeft = totalDuration - currPosition
            var rms: Float32 = 0
            if timeLeft <= 5 {
                // don't trim silence from the last 5 seconds
                rms = 1
            } else {
                rms = (channelCount == 1) ? calculateRms(bufferListPointer[0]) : calculateStereoRms(bufferListPointer[0], rightBuffer: bufferListPointer[1])
            }

            if rms > minRMS, !foundGap {
                // the RMS is higher than our minimum and we aren't currently in a gap, just play it
                buffers.append(audioBuffer)
            } else if foundGap, rms > minRMS || buffersSavedDuringGap.count() > maxSilenceAmountToSave {
                foundGap = false
                // we've come to the end of a gap (or we've had a suspiscious amount of gap), piece back together the audio
                if buffersSavedDuringGap.count() < minGapSizeInFrames {
                    // we don't have enough gap to remove, just push
                    while buffersSavedDuringGap.canPop() {
                        buffers.append(buffersSavedDuringGap.pop()!)
                    }

                    buffers.append(audioBuffer)
                } else {
                    for index in 0 ... amountOfSilentFramesToReInsert {
                        if index < amountOfSilentFramesToReInsert {
                            buffers.append(buffersSavedDuringGap.pop()!)
                        } else {
                            // fade out the last frame to avoid a jarring re-attach
                            let buffer = buffersSavedDuringGap.pop()!
                            AudioUtils.fadeAudio(buffer, fadeOut: true, channelCount: channelCount)
                            buffers.append(buffer)
                        }
                    }

                    // pop all the ones we don't need after that
                    while buffersSavedDuringGap.canPop(), buffersSavedDuringGap.count() > (amountOfSilentFramesToReInsert - 1) {
                        _ = buffersSavedDuringGap.pop()
                        let secondsSaved = Double((audioPCMBuffer?.frameLength)!) / audioFile.fileFormat.sampleRate
                        StatsManager.shared.addTimeSavedDynamicSpeed(secondsSaved)
                    }

                    while buffersSavedDuringGap.canPop() {
                        buffers.append(buffersSavedDuringGap.pop()!)
                    }

                    // fade back in the new frame
                    AudioUtils.fadeAudio(audioBuffer, fadeOut: false, channelCount: channelCount)
                    buffers.append(audioBuffer)
                }
            } else if rms < minRMS, !foundGap {
                // we are at the start of a gap, save this clip and keep going
                foundGap = true
                buffersSavedDuringGap.push(audioBuffer)
            } else if rms < minRMS, foundGap {
                // we are inside a gap we've already found
                buffersSavedDuringGap.push(audioBuffer)
            }
        } else {
            buffers.append(audioBuffer)
        }

        objc_sync_exit(lock)
        return buffers
    }

    private func scheduleForPlayback(buffer: BufferedAudio) {
        // the play task will signal us when it needs more buffer, but it will keep signalling as long as the buffer is low, so keep calling wait until we get below the high point
        while !cancelled.value, bufferManager.bufferLength() >= bufferManager.highBufferPoint {
            bufferManager.bufferSemaphore.wait()
        }

        if !cancelled.value {
            bufferManager.push(buffer)
        }
    }

    private func calculateRms(_ audioBuffer: AudioBuffer) -> Float32 {
        var sum: Float32 = 0.0
        let bufferSize = Float32(audioBuffer.mDataByteSize) / bufferByteSize
        guard let buffer = audioBuffer.mData?.bindMemory(to: Float32.self, capacity: Int(bufferSize)) else { return 0 }

        for i in 0 ..< Int(bufferSize) {
            sum += buffer[i] * buffer[i]
        }

        return sqrt(sum / bufferSize)
    }

    private func calculateStereoRms(_ leftBuffer: AudioBuffer, rightBuffer: AudioBuffer) -> Float32 {
        var sum: Float32 = 0.0
        let leftSize = Float32(leftBuffer.mDataByteSize) / bufferByteSize
        if let left = leftBuffer.mData?.bindMemory(to: Float32.self, capacity: Int(leftSize)) {
            for i in 0 ..< Int(leftSize) {
                sum += left[i] * left[i]
            }
        }

        let leftRms = sqrt(sum / leftSize)

        sum = 0
        let rightSize = Float32(rightBuffer.mDataByteSize) / bufferByteSize
        if let right = rightBuffer.mData?.bindMemory(to: Float32.self, capacity: Int(rightSize)) {
            for i in 0 ..< Int(rightSize) {
                sum += right[i] * right[i]
            }
        }

        let rightRms = sqrt(sum / rightSize)

        return (leftRms + rightRms) / 2
    }

    private func gapSizeForSilenceAmount() -> Int {
        switch trimSilence {
        case .low:
            return 20
        case .medium:
            return 16
        case .high:
            return 4
        case .off:
            return 0
        }
    }

    private func framesToReInsertForSilenceAmount() -> Int {
        switch trimSilence {
        case .low:
            return 14
        case .medium:
            return 12
        case .high, .off:
            return 0
        }
    }

    private func minRMSForSilenceAmount() -> Float32 {
        switch trimSilence {
        case .low:
            return 0.0055
        case .medium:
            return 0.00511
        case .high:
            return 0.005
        case .off:
            return 0
        }
    }

    private func framePositionForTime(_ time: TimeInterval) -> (framePosition: Int64, passedEndOfFile: Bool) {
        let totalFrames = Double(cachedFrameCount)
        let totalSeconds = totalFrames / audioFile.fileFormat.sampleRate
        let percentSeek = time / totalSeconds

        // Ignore any invalid values
        guard percentSeek.isNumeric else {
            return(0, false)
        }

        return (Int64(totalFrames * percentSeek), percentSeek >= 1)
    }
}
