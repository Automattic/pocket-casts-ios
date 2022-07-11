import Combine
import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import WatchKit

class EffectsViewModel: ObservableObject {
    private var playSource = PlaySourceHelper.playSourceViewModel

    var playbackSpeed: Double {
        playSource.playbackSpeed
    }

    var trimSilenceAvailable: Bool {
        playSource.trimSilenceAvailable
    }

    var volumeBoostAvailable: Bool {
        playSource.volumeBoostAvailable
    }

    var trimSilenceEnabled: Bool {
        get {
            playSource.trimSilenceEnabled
        }
        set {
            playSource.trimSilenceEnabled = newValue
        }
    }

    var volumeBoostEnabled: Bool {
        get {
            playSource.volumeBoostEnabled
        }
        set {
            playSource.volumeBoostEnabled = newValue
        }
    }

    private var cancellables = Set<AnyCancellable>()
    init() {
        Publishers.Merge(
            Publishers.Notification.dataUpdated,
            Publishers.Notification.playbackEffectsChanged
        )
        .receive(on: RunLoop.main)
        .sink { [unowned self] _ in
            self.objectWillChange.send()
        }
        .store(in: &cancellables)
    }

    func decreasePlaybackSpeed() {
        playSource.decreasePlaybackSpeed()
    }

    func increasePlaybackSpeed() {
        playSource.increasePlaybackSpeed()
    }

    func changeSpeedInterval() {
        playSource.changeSpeedInterval()
    }
}
