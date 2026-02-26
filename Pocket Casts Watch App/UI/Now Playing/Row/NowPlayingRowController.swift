import Foundation
import WatchKit

class NowPlayingRowController: NSObject {
    @IBOutlet var icon: WKInterfaceImage!
    @IBOutlet var label: WKInterfaceLabel!
    @IBOutlet var playingPodcast: WKInterfaceLabel!
    @IBOutlet var topLevelGroup: WKInterfaceGroup!
    func setNowPlayingInfo(isPlaying: Bool, podcastName: String?) {
        label.setText(L10n.nowPlaying)
        updatePlayingState(isPlaying: isPlaying)
        guard let name = podcastName else {
            playingPodcast.setHidden(true)
            return
        }
        playingPodcast.setText(name)
        playingPodcast.setHidden(false)
        topLevelGroup.setAccessibilityLabel(L10n.nowPlayingItem(name))
    }

    func updatePlayingState(isPlaying: Bool) {
        if isPlaying {
            icon.setImageNamed("nowplaying")
            icon.startAnimating()
        } else {
            icon.stopAnimating()
            icon.setImageNamed("notplaying")
        }
    }
}
