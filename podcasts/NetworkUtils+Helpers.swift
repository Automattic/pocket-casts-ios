import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

extension NetworkUtils {
    func downloadEpisodeRequested(autoDownloadStatus: AutoDownloadStatus, _ allowed: ((_ later: Bool) -> Void)?, disallowed: (() -> Void)?) {
        let mobileDataAllowed = autoDownloadStatus == .autoDownloaded ? Settings.autoDownloadMobileDataAllowed() : Settings.mobileDataAllowed()

        if mobileDataAllowed || isConnectedToUnexpensiveConnection() {
            allowed?(false)

            return
        }

        let optionsPicker = OptionsPicker(title: nil)
        let downloadAction = OptionAction(label: L10n.podcastDownloadNow, icon: nil) {
            allowed?(false)
        }
        let laterAction = OptionAction(label: L10n.queueForLater, icon: nil) {
            allowed?(true)
        }
        laterAction.outline = true

        optionsPicker.addAttributedDescriptiveActions(title: L10n.notOnWifi, message: L10n.downloadDataWarningWithSettingsLink("pktc://settings/storage-and-data"), icon: "option-alert", actions: [downloadAction, laterAction])

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

        let optionsPicker = OptionsPicker(title: nil)
        let streamAction = OptionAction(label: L10n.podcastStreamConfirmation, icon: nil) {
            allowed?()
        }
        optionsPicker.addAttributedDescriptiveActions(title: L10n.notOnWifi, message: L10n.podcastStreamDataWarningWithSettings("pktc://settings/storage-and-data"), icon: "option-alert", actions: [streamAction])

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

        let optionsPicker = OptionsPicker(title: nil)
        let uploadAction = OptionAction(label: "Upload Now", icon: nil) {
            allowed?(false)
        }
        let laterAction = OptionAction(label: L10n.queueForLater, icon: nil) {
            allowed?(true)
        }
        laterAction.outline = true
        optionsPicker.addDescriptiveActions(title: L10n.notOnWifi, message: "", icon: "option-alert", actions: [uploadAction, laterAction])

        optionsPicker.setNoActionCallback {
            disallowed?()
        }

        optionsPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }
}
