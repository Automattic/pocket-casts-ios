import Foundation
import SwiftUI

class BackgroundPlaybackManagement {

    let playbackManager: PlaybackManager

    init(playbackManager: PlaybackManager = .shared) {
        self.playbackManager = playbackManager
    }

    /// Configures the background media session in response to SwiftUI `scenePhase`
    /// changes, for apps that use the SwiftUI app lifecycle instead of an
    /// `AppDelegate` (e.g. tvOS).
    func handle(scenePhase: ScenePhase) {
        switch scenePhase {
        case .background, .inactive:
            didEnterBackground()
        default:
            break
        }
    }

    func didEnterBackground() {
        playbackManager.ensureBackgroundMediaSessionConfiguration()
    }
}
