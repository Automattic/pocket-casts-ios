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

        if FeatureFlag.liquidGlass.enabled {
            let alert = UIAlertController(title: L10n.notOnWifi, message: L10n.downloadDataWarningAlert, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: L10n.podcastDownloadNow, style: .default) { _ in
                allowed?(false)
            })
            alert.addAction(UIAlertAction(title: L10n.queueForLater, style: .default) { _ in
                allowed?(true)
            })
            alert.addAction(UIAlertAction(title: L10n.settings, style: .default) { _ in
                if let url = URL(string: "pktc://settings/storage-and-data") {
                    UIApplication.shared.open(url)
                }
            })
            alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
                disallowed?()
            })
            SceneHelper.rootViewController()?.present(alert, animated: true)
        } else {
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
    }

    func streamEpisodeRequested(_ allowed: (() -> Void)?, disallowed: (() -> Void)?) {
        if Settings.mobileDataAllowed() || isConnectedToUnexpensiveConnection() {
            allowed?()

            return
        }

        if FeatureFlag.liquidGlass.enabled {
            let alert = UIAlertController(title: L10n.notOnWifi, message: L10n.podcastStreamDataWarningAlert, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: L10n.podcastStreamConfirmation, style: .default) { _ in
                allowed?()
            })
            alert.addAction(UIAlertAction(title: L10n.settings, style: .default) { _ in
                if let url = URL(string: "pktc://settings/storage-and-data") {
                    UIApplication.shared.open(url)
                }
            })
            alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
                disallowed?()
            })
            SceneHelper.rootViewController()?.present(alert, animated: true)
        } else {
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
    }

    // MARK: - Upload Helpers

    func uploadEpisodeRequested(_ allowed: ((_ later: Bool) -> Void)?, disallowed: (() -> Void)?) {
        let mobileDataAllowed = !ServerSettings.userEpisodeOnlyOnWifi()

        if mobileDataAllowed || isConnectedToUnexpensiveConnection() {
            allowed?(false)

            return
        }

        if FeatureFlag.liquidGlass.enabled {
            let alert = UIAlertController(title: L10n.notOnWifi, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: L10n.podcastUploadConfirmation, style: .default) { _ in
                allowed?(false)
            })
            alert.addAction(UIAlertAction(title: L10n.queueForLater, style: .default) { _ in
                allowed?(true)
            })
            alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
                disallowed?()
            })
            SceneHelper.rootViewController()?.present(alert, animated: true)
        } else {
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
}
