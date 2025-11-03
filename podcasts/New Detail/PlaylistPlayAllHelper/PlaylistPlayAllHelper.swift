import Foundation
import PocketCastsUtils

class PlaylistPlayAllHelper {
    enum Action {
        case close
        case showSecondPicker
        case replaceAndPlay
        case saveAndPlay
        case dismiss
    }
    class func playAll(confirmAction: @escaping (Action) -> Void) {
        if PlaybackManager.shared.queue.upNextCount() == 0 {
            // there's nothing to over-write, so nothing to confirm either
            confirmAction(.replaceAndPlay)
            return
        }

        let save = OptionAction(
            label: L10n.playlistPlayAllOptionSaveQueue,
            icon: nil,
            action: {
                confirmAction(.saveAndPlay)
            }
        )

        let replace = OptionAction(
            label: L10n.playlistPlayAllOptionReplaceQueue,
            icon: nil,
            action: {
                confirmAction(.showSecondPicker)
                displayOverridePicker(confirmAction: confirmAction)
            }
        )
        replace.outline = true

        let picker = OptionsPicker(title: "")
        picker.addDescriptiveActions(
            title: L10n.playlistPlayAllPickerTitle,
            message: L10n.playlistPlayAllPickerMessage,
            icon: "playlist_picker_upnext",
            actions: [
                save,
                replace
            ]
        )
        picker.setNoActionCallback {
            confirmAction(.dismiss)
        }
        picker.show(statusBarStyle: .default)
    }

    private class func displayOverridePicker(confirmAction: @escaping (Action) -> Void) {
        let replace = OptionAction(
            label: L10n.playlistPlayAllOptionReplaceQueue,
            icon: nil,
            action: {
                confirmAction(.replaceAndPlay)
            }
        )
        replace.destructive = true

        let close = OptionAction(
            label: L10n.close,
            icon: nil,
            action: {
                confirmAction(.close)
            }
        )
        close.outline = true

        let picker = OptionsPicker(title: "")
        picker.addDescriptiveActions(
            title: L10n.playlistPlayAllReplacePickerTitle,
            message: L10n.playlistPlayAllReplacePickerMessage,
            icon: "playlist_picker_upnext_replace",
            actions: [
                replace,
                close
            ]
        )
        picker.setNoActionCallback {
            confirmAction(.dismiss)
        }
        picker.show(statusBarStyle: .default)
    }
}
