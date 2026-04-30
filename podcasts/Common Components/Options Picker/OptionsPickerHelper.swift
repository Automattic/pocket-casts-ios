import PocketCastsUtils
import UIKit

class OptionsPickerHelper {
    class func playAllWarning(episodeCount: Int, confirmAction: @escaping () -> Void) {
        if PlaybackManager.shared.queue.upNextCount() == 0 {
            confirmAction()
            return
        }

        let playableEpisodesLabel = episodeCount == 1 ? L10n.playerOptionsPlayEpisodeSingular : L10n.playerOptionsPlayEpisodesPlural(episodeCount.localized())

        if FeatureFlag.liquidGlass.enabled {
            let alert = UIAlertController(title: L10n.playAll, message: L10n.playerOptionsPlayAllMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: playableEpisodesLabel, style: .default) { _ in
                confirmAction()
            })
            alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel))
            SceneHelper.rootViewController()?.present(alert, animated: true)
        } else {
            let playAction = OptionAction(label: playableEpisodesLabel, icon: nil, action: {
                confirmAction()
            })
            let warningPicker = OptionsPicker(title: "")
            warningPicker.addDescriptiveActions(title: L10n.playAll, message: L10n.playerOptionsPlayAllMessage, icon: "filter_play", actions: [playAction])
            warningPicker.show(statusBarStyle: .default)
        }
    }
}
