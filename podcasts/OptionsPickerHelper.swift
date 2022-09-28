import PocketCastsUtils
import UIKit

class OptionsPickerHelper {
    class func playAllWarning(episodeCount: Int, confirmAction: @escaping () -> Void) {
        if PlaybackManager.shared.queue.upNextCount() == 0 {
            // there's nothing to over-write, so nothing to confirm either
            confirmAction()
            return
        }

        let playableEpisodesLabel = episodeCount == 1 ? L10n.playerOptionsPlayEpisodeSingular : L10n.playerOptionsPlayEpisodesPlural(episodeCount.localized())
        let playAction = OptionAction(label: playableEpisodesLabel, icon: nil, action: {
            confirmAction()
        })

        let warningPicker = OptionsPicker(title: "")
        warningPicker.addDescriptiveActions(title: L10n.playAll, message: L10n.playerOptionsPlayAllMessage, icon: "filter_play", actions: [playAction])

        warningPicker.show(statusBarStyle: .default)
    }
}
