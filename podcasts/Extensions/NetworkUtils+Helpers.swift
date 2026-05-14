import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

extension NetworkUtils {
    func downloadEpisodeRequested(autoDownloadStatus: AutoDownloadStatus, _ allowed: ((_ later: Bool) -> Void)?, disallowed: (() -> Void)?) {
        let mobileDataAllowed = autoDownloadStatus == .autoDownloaded ? Settings.autoDownloadMobileDataAllowed() : Settings.mobileDataAllowed()

        if mobileDataAllowed || isConnectedToUnexpensiveConnection() {
            allowed?(false)

            return
        }

        let downloadAction = OptionAction(label: L10n.podcastDownloadNow, icon: nil) {
            allowed?(false)
        }
        let laterAction = OptionAction(label: L10n.queueForLater, icon: nil) {
            allowed?(true)
        }
        laterAction.outline = true

        var actions: [OptionAction] = [downloadAction, laterAction]
        if !Settings.mobileDataAllowed() {
            actions.append(OptionAction(label: L10n.settings, icon: nil) {
                if let url = URL(string: "pktc://settings/storage-and-data") {
                    UIApplication.shared.open(url)
                }
            })
        }

        let optionsPicker = OptionsPicker(title: nil)
        optionsPicker.addDescriptiveActions(
            title: L10n.notOnWifi,
            message: L10n.downloadDataWarningAlert,
            icon: "option-alert",
            actions: actions
        )
        optionsPicker.setNoActionCallback {
            disallowed?()
        }
        optionsPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }

    func streamEpisodeRequested(_ allowed: (() -> Void)?, disallowed: (() -> Void)?) {
        if Settings.mobileDataAllowed() || isConnectedToUnexpensiveConnection() {
            allowed?()

            return
        }

        let streamAction = OptionAction(label: L10n.podcastStreamConfirmation, icon: nil) {
            allowed?()
        }

        var actions: [OptionAction] = [streamAction]
        if !Settings.mobileDataAllowed() {
            actions.append(OptionAction(label: L10n.settings, icon: nil) {
                if let url = URL(string: "pktc://settings/storage-and-data") {
                    UIApplication.shared.open(url)
                }
            })
        }

        let optionsPicker = OptionsPicker(title: nil)
        optionsPicker.addDescriptiveActions(
            title: L10n.notOnWifi,
            message: L10n.podcastStreamDataWarningAlert,
            icon: "option-alert",
            actions: actions
        )
        optionsPicker.setNoActionCallback {
            disallowed?()
        }
        optionsPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }

    // MARK: - Upload Helpers

    func uploadEpisodeRequested(_ allowed: ((_ later: Bool) -> Void)?, disallowed: (() -> Void)?) {
        let mobileDataAllowed = !ServerSettings.userEpisodeOnlyOnWifi()

        if mobileDataAllowed || isConnectedToUnexpensiveConnection() {
            allowed?(false)

            return
        }

        let uploadAction = OptionAction(label: L10n.podcastUploadConfirmation, icon: nil) {
            allowed?(false)
        }
        let laterAction = OptionAction(label: L10n.queueForLater, icon: nil) {
            allowed?(true)
        }
        laterAction.outline = true

        let optionsPicker = OptionsPicker(title: nil)
        optionsPicker.addDescriptiveActions(
            title: L10n.notOnWifi,
            message: nil,
            icon: "option-alert",
            actions: [uploadAction, laterAction]
        )
        optionsPicker.setNoActionCallback {
            disallowed?()
        }
        optionsPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }
}
