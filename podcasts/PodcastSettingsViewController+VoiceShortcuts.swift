import Foundation
import IntentsUI
import UIKit

extension PodcastSettingsViewController: INUIEditVoiceShortcutViewControllerDelegate, INUIAddVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        updateExistingSortcutData()
        controller.dismiss(animated: true, completion: nil)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
    }

    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        updateExistingSortcutData()
        controller.dismiss(animated: true, completion: nil)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
    }

    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
    }

    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        updateExistingSortcutData()
        controller.dismiss(animated: true, completion: nil)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
    }

    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
    }

    func existingSiriVoiceShortcut() -> INVoiceShortcut! {
        if let existingShortcut = existingShortcut as? INVoiceShortcut {
            return existingShortcut
        }

        return nil
    }
}
