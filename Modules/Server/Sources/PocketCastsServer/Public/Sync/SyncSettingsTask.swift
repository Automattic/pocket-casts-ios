import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class SyncSettingsTask: ApiBaseTask {

    let shouldUseNewSync: Bool

    init(shouldUseNewSync: Bool) {
        self.shouldUseNewSync = shouldUseNewSync
    }

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "user/named_settings/update"
        do {
            var settingsRequest = Api_NamedSettingsRequest()
            settingsRequest.m = "iPhone"

            if shouldUseNewSync {
                //New sync logic will go here in future PRs
            } else {
                if ServerSettings.skipBackNeedsSyncing() {
                    settingsRequest.settings.skipBack.value = Int32(ServerSettings.skipBackTime())
                }
                if ServerSettings.skipForwardNeedsSyncing() {
                    settingsRequest.settings.skipForward.value = Int32(ServerSettings.skipForwardTime())
                }
                if ServerSettings.marketingOptInNeedsSyncing() {
                    settingsRequest.settings.marketingOptIn.value = ServerSettings.marketingOptIn()
                }
                if SubscriptionHelper.subscriptionGiftAcknowledgementNeedsSyncing() {
                    settingsRequest.settings.freeGiftAcknowledgement.value = SubscriptionHelper.subscriptionGiftAcknowledgement()
                }
                if ServerSettings.homeGridSortOrderNeedsSyncing() {
                    settingsRequest.settings.gridOrder.value = ServerConverter.convertToServerSortType(clientType: ServerSettings.homeGridSortOrder())
                }
            }

            let data = try settingsRequest.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            if let response = response, httpStatus == ServerConstants.HttpConstants.ok {
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

            if shouldUseNewSync {
                // New sync logic will got here in future PRs
            } else {
                if settings.skipForward.changed.value {
                    let skipForwardTime = Int(settings.skipForward.value.value)
                    if skipForwardTime > 0, skipForwardTime != ServerSettings.skipForwardTime() {
                        ServerSettings.setSkipForwardTime(skipForwardTime, syncChange: false)
                    }
                }

                if settings.skipBack.changed.value {
                    let skipBackTime = Int(settings.skipBack.value.value)
                    if skipBackTime > 0, skipBackTime != ServerSettings.skipBackTime() {
                        ServerSettings.setSkipBackTime(skipBackTime, syncChange: false)
                    }
                }

                if settings.marketingOptIn.changed.value {
                    let marketingOptIn = settings.marketingOptIn.value.value
                    ServerSettings.setMarketingOptIn(marketingOptIn)
                }

                if settings.freeGiftAcknowledgement.changed.value {
                    let acknowledgement = settings.freeGiftAcknowledgement.value.value
                    SubscriptionHelper.setSubscriptionGiftAcknowledgement(acknowledgement)
                }
                if settings.gridOrder.changed.value {
                    let newOrder = ServerConverter.convertToClientSortType(serverType: settings.gridOrder.value.value)
                    ServerSettings.setHomeGridSortOrder(newOrder, syncChange: false)
                }
            }

            ServerSettings.setSkipBackSynced()
            ServerSettings.setSkipForwardSynced()
            ServerSettings.marketingOptInSynced()
            ServerSettings.setHomeGridSortOrderSynced()
            SubscriptionHelper.subscriptionGiftAcknowledgementSynced()
        } catch {
            FileLog.shared.addMessage("SyncSettingsTask decoding response failed \(error.localizedDescription)")
        }
    }
}
