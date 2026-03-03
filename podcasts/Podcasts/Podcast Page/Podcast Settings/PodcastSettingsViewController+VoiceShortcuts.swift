import Foundation
import IntentsUI
import UIKit

extension PodcastSettingsViewController: INUIEditVoiceShortcutViewControllerDelegate, INUIAddVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        updateExistingSortcutData()
        controller.dismiss(animated: true, completion: nil)
    }

    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        updateExistingSortcutData()
        controller.dismiss(animated: true, completion: nil)
        Analytics.track(.podcastSettingsSiriShortcutRemoved)
    }

    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        updateExistingSortcutData()
        controller.dismiss(animated: true, completion: nil)
        Analytics.track(.podcastSettingsSiriShortcutAdded)
    }

    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func existingSiriVoiceShortcut() -> INVoiceShortcut! {
        if let existingShortcut = existingShortcut as? INVoiceShortcut {
            return existingShortcut
        }

        return nil
    }
}
