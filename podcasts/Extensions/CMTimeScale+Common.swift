extension CMTimeScale {
    // A common 44.1 kHz sample rate for audio
    public static var audio: Self = 44100
    // A common multiple of typical video formats like 24 & 30 fps.
    // See https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/06_MediaRepresentations.html#//apple_ref/doc/uid/TP40010188-CH2-SW8
    static var video: Self = 600
}
