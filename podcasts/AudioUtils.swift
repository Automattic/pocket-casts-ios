import AVFoundation
import Foundation
import Accelerate
import PocketCastsUtils

class AudioUtils {
    private static let bufferLength = UInt32(Constants.Audio.defaultFrameSize)
    private static let bufferByteSize = Float32(MemoryLayout<Float32>.size)

    class func fadeAudio(_ audio: BufferedAudio, fadeOut: Bool, channelCount: UInt32) {
        if FeatureFlag.accelerateEffects.enabled {
            newFadeAudio(audio, fadeOut: fadeOut, channelCount: channelCount)
        } else {
            oldFadeAudio(audio, fadeOut: fadeOut, channelCount: channelCount)
        }
    }

    class func oldFadeAudio(_ audio: BufferedAudio, fadeOut: Bool, channelCount: UInt32) {
        let bufferList = UnsafeMutableAudioBufferListPointer(audio.audioBuffer.mutableAudioBufferList)
        let length = Float32(bufferList[0].mDataByteSize) / bufferByteSize
        let data = bufferList[0].mData?.bindMemory(to: Float32.self, capacity: Int(length))

        AudioUtils.oldPerformFade(fadeOut, length: length, data: data)

        if channelCount > 1 {
            let extraChannelLength = Float32(bufferList[1].mDataByteSize) / bufferByteSize
            let extraChannelData = bufferList[1].mData?.bindMemory(to: Float32.self, capacity: Int(extraChannelLength))

            AudioUtils.oldPerformFade(fadeOut, length: extraChannelLength, data: extraChannelData)
        }
    }

    class func oldPerformFade(_ fadeOut: Bool, length: Float32, data: UnsafeMutablePointer<Float32>?) {
        guard let data = data else { return }

        for i in 0 ..< Int(length) {
            if fadeOut {
                data[i] = data[i] * ((length - 1) - Float32(i)) / (length - 1)
            } else {
                data[i] = data[i] * Float32(i) / (length - 1)
            }
        }
    }

    class func newFadeAudio(_ audio: BufferedAudio, fadeOut: Bool, channelCount: UInt32) {
        let bufferList = UnsafeMutableAudioBufferListPointer(audio.audioBuffer.mutableAudioBufferList)
        let length = vDSP_Length(bufferList[0].mDataByteSize) / vDSP_Length(bufferByteSize)
        let data = bufferList[0].mData?.bindMemory(to: Float32.self, capacity: Int(length))

        AudioUtils.newPerformFade(fadeOut, length: length, data: data)

        if channelCount > 1 {
            let extraChannelLength = vDSP_Length(bufferList[1].mDataByteSize) / vDSP_Length(bufferByteSize)
            let extraChannelData = bufferList[1].mData?.bindMemory(to: Float32.self, capacity: Int(extraChannelLength))

            AudioUtils.newPerformFade(fadeOut, length: extraChannelLength, data: extraChannelData)
        }
    }

    class func newPerformFade(_ fadeOut: Bool, length: vDSP_Length, data: UnsafeMutablePointer<Float32>?) {
        guard let data = data else { return }

        var ramp = [Float32](repeating: 0, count: Int(length))

        if fadeOut {
            vDSP_vgen([1.0], [0.0], &ramp, 1, length)
        } else {
            vDSP_vgen([0.0], [1.0], &ramp, 1, length)
        }

        vDSP_vmul(data, 1, ramp, 1, data, 1, length)
    }


    class func calculateStereoRms(_ leftBuffer: AudioBuffer, rightBuffer: AudioBuffer) -> Float32 {
        let leftRms = calculateRms(leftBuffer)
        let rightRms = calculateRms(rightBuffer)

        return (leftRms + rightRms) / 2
    }

    class func calculateRms(_ audioBuffer: AudioBuffer) -> Float32 {

        if FeatureFlag.accelerateEffects.enabled {
            return newCalculateRms(audioBuffer)
        }

        var sum: Float32 = 0.0
        let bufferSize = Float32(audioBuffer.mDataByteSize) / bufferByteSize
        guard let buffer = audioBuffer.mData?.bindMemory(to: Float32.self, capacity: Int(bufferSize)) else { return 0 }

        for i in 0 ..< Int(bufferSize) {
            sum += buffer[i] * buffer[i]
        }

        return sqrt(sum / bufferSize)
    }

    class func newCalculateRms(_ audioBuffer: AudioBuffer) -> Float32 {
        let bufferSize = Float32(audioBuffer.mDataByteSize) / bufferByteSize
        guard let buffer = audioBuffer.mData?.bindMemory(to: Float32.self, capacity: Int(bufferSize)) else { return 0 }

        let stride = vDSP_Stride(1)

        let n = vDSP_Length(bufferSize)

        var c = Float32()

        vDSP_rmsqv(buffer,
                   stride,
                   &c,
                   n)

        return c
    }
}
