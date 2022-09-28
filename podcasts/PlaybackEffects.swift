import PocketCastsDataModel
import UIKit

enum TrimSilenceAmount: Int {
    case off = 0, low = 3, medium = 5, high = 10

    var description: String {
        switch self {
        case .off:
            return L10n.off
        case .low:
            return L10n.playbackEffectTrimSilenceMild
        case .medium:
            return L10n.playbackEffectTrimSilenceMedium
        case .high:
            return L10n.playbackEffectTrimSilenceMax
        }
    }

    func isEnabled() -> Bool {
        self != .off
    }
}

class PlaybackEffects {
    internal static let defaultRemoveSilenceAmount = 3

    var playbackSpeed: Double = 1.0
    var trimSilence: TrimSilenceAmount = .off
    var volumeBoost = false
    var isGlobal: Bool = true

    class func effectsFor(podcast: Podcast) -> PlaybackEffects {
        if !podcast.overrideGlobalEffects { return globalEffects() }

        let effects = PlaybackEffects()

        effects.isGlobal = false
        effects.trimSilence = convertToTrimSilenceAmount(Int(podcast.trimSilenceAmount))
        effects.volumeBoost = podcast.boostVolume
        effects.playbackSpeed = podcast.playbackSpeed

        return effects
    }

    class func globalEffects() -> PlaybackEffects {
        let effects = PlaybackEffects()
        effects.isGlobal = true
        let removeSilenceAmount = UserDefaults.standard.integer(forKey: Constants.UserDefaults.globalRemoveSilence)
        effects.trimSilence = convertToTrimSilenceAmount(removeSilenceAmount)
        effects.volumeBoost = UserDefaults.standard.bool(forKey: Constants.UserDefaults.globalVolumeBoost)

        let savedSpeed = UserDefaults.standard.double(forKey: Constants.UserDefaults.globalPlaybackSpeed)
        var roundedSpeed = round(savedSpeed * 10.0) / 10.0
        if roundedSpeed < 0.5 {
            roundedSpeed = 1.0
        }
        effects.playbackSpeed = roundedSpeed

        return effects
    }

    func effectsEnabled() -> Bool {
        trimSilence.isEnabled() || volumeBoost || playbackSpeed != 1.0
    }

    func toggleDefinedSpeedInterval() {
        if playbackSpeed < 1 || playbackSpeed >= 2 {
            playbackSpeed = 1
        } else if playbackSpeed < 1.5 {
            playbackSpeed = 1.5
        } else if playbackSpeed < 2 {
            playbackSpeed = 2
        }
    }

    func incrementSpeedBy(_ value: Double) {
        var currentSpeed = playbackSpeed

        currentSpeed += value
        if currentSpeed > SharedConstants.PlaybackEffects.maximumPlaybackSpeed {
            currentSpeed = 1.0
        }

        playbackSpeed = currentSpeed
    }

    private class func convertToTrimSilenceAmount(_ value: Int) -> TrimSilenceAmount {
        if let amount = TrimSilenceAmount(rawValue: value) {
            return amount
        }

        return value > 0 ? .low : .off
    }
}
