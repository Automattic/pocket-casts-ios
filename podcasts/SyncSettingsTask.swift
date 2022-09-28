import DataModel
import Foundation
import SwiftProtobuf
import Utils

class SyncSettingsTask: ApiBaseTask {
    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "user/named_settings/update"
        do {
            var settingsRequest = Api_NamedSettingsRequest()
            settingsRequest.m = "iPhone"

            if Settings.skipBackNeedsSyncing() {
                settingsRequest.settings.skipBack = Google_Protobuf_Int32Value(Int32(Settings.skipBackTime()))
            }
            if Settings.skipForwardNeedsSyncing() {
                settingsRequest.settings.skipForward = Google_Protobuf_Int32Value(Int32(Settings.skipForwardTime()))
            }
            if Settings.marketingOptInNeedsSyncing() {
                settingsRequest.settings.marketingOptIn = Google_Protobuf_BoolValue(Settings.marketingOptIn())
            }
            if Settings.subscriptionGiftAcknowledgementNeedsSyncing() {
                settingsRequest.settings.freeGiftAcknowledgement = Google_Protobuf_BoolValue(Settings.subscriptionGiftAcknowledgement())
            }
            let data = try settingsRequest.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            if let response = response, httpStatus == Server.HttpConstants.ok {
                process(serverData: response)
            } else {
                FileLog.shared.addMessage("SyncSettingsTask Unable to sync with server got status \(httpStatus)")
            }
        } catch {
            FileLog.shared.addMessage("SyncSettingsTask Protobuf Encoding failed")
        }
    }

    private func process(serverData: Data) {
        do {
            let settings = try Api_NamedSettingsResponse(serializedData: serverData)

            if settings.skipForward.changed.value {
                let skipForwardTime = Int(settings.skipForward.value.value)
                if skipForwardTime > 0, skipForwardTime != Settings.skipForwardTime() {
                    Settings.setSkipForwardTime(skipForwardTime, syncChange: false)
                }
            }

            if settings.skipBack.changed.value {
                let skipBackTime = Int(settings.skipBack.value.value)
                if skipBackTime > 0, skipBackTime != Settings.skipBackTime() {
                    Settings.setSkipBackTime(skipBackTime, syncChange: false)
                }
            }

            let marketingOptIn = Bool(settings.marketingOptIn.value.value)
            Settings.setMarketingOptIn(marketingOptIn)

            let acknowledgement = Bool(settings.freeGiftAcknowledgement.value.value)
            Settings.setSubscriptionGiftAcknowledgement(acknowledgement)

            Settings.setSkipBackSynced()
            Settings.setSkipForwardSynced()
            Settings.marketingOptInSynced()
            Settings.subscriptionGiftAcknowledgementSynced()
        } catch {
            FileLog.shared.addMessage("SyncSettingsTask decoding response failed")
        }
    }
}
