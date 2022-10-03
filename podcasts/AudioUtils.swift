import AVFoundation
import Foundation

class AudioUtils {
    private static let bufferLength = UInt32(Constants.Audio.defaultFrameSize)
    private static let bufferByteSize = Float32(MemoryLayout<Float32>.size)

    class func fadeAudio(_ audio: BufferedAudio, fadeOut: Bool, channelCount: UInt32) {
        let bufferList = UnsafeMutableAudioBufferListPointer(audio.audioBuffer.mutableAudioBufferList)
        let length = Float32(bufferList[0].mDataByteSize) / bufferByteSize
        let data = bufferList[0].mData?.bindMemory(to: Float32.self, capacity: Int(length))

        AudioUtils.performFade(fadeOut, length: length, data: data)

        if channelCount > 1 {
            let extraChannelLength = Float32(bufferList[1].mDataByteSize) / bufferByteSize
            let extraChannelData = bufferList[1].mData?.bindMemory(to: Float32.self, capacity: Int(extraChannelLength))

            AudioUtils.performFade(fadeOut, length: extraChannelLength, data: extraChannelData)
        }
    }

    private class func performFade(_ fadeOut: Bool, length: Float32, data: UnsafeMutablePointer<Float32>?) {
        guard let data = data else { return }

        for i in 0 ..< Int(length) {
            if fadeOut {
                data[i] = data[i] * (length - Float32(i)) / length
            } else {
                data[i] = data[i] * Float32(i) / length
            }
        }
    }
}
