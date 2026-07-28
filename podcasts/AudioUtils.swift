import AVFoundation
import Foundation
import Accelerate
import PocketCastsUtils

class AudioUtils {
    private static let bufferLength = UInt32(Constants.Audio.defaultFrameSize)
    private static let bufferByteSize = Float32(MemoryLayout<Float32>.size)

    class func fadeAudio(_ audio: BufferedAudio, fadeOut: Bool, channelCount: UInt32) {
        let bufferList = UnsafeMutableAudioBufferListPointer(audio.audioBuffer.mutableAudioBufferList)
        let length = vDSP_Length(bufferList[0].mDataByteSize) / vDSP_Length(bufferByteSize)
        let data = bufferList[0].mData?.bindMemory(to: Float32.self, capacity: Int(length))

        AudioUtils.performFade(fadeOut, length: length, data: data)

        if channelCount > 1 {
            let extraChannelLength = vDSP_Length(bufferList[1].mDataByteSize) / vDSP_Length(bufferByteSize)
            let extraChannelData = bufferList[1].mData?.bindMemory(to: Float32.self, capacity: Int(extraChannelLength))

            AudioUtils.performFade(fadeOut, length: extraChannelLength, data: extraChannelData)
        }
    }

    class func performFade(_ fadeOut: Bool, length: vDSP_Length, data: UnsafeMutablePointer<Float32>?) {
        guard let data else { return }

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
