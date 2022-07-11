import AVFoundation
import Foundation

struct BufferedAudio {
    var audioBuffer: AVAudioPCMBuffer
    var framePosition: AVAudioFramePosition
    var shouldFadeOut: Bool
    var shouldFadeIn: Bool
}
