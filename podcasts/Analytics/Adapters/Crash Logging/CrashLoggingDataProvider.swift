import Foundation
import PocketCastsServer
import AutomatticRemoteLogging

class CrashLoggingDataProvider: AutomatticRemoteLogging.CrashLoggingDataProvider {
    let sentryDSN = ApiCredentials.sentryDSN
    let userHasOptedOut = false
    let shouldEnableAutomaticSessionTracking = true
    var currentUser: AutomatticTracksModel.TracksUser? {
        guard SyncManager.isUserLoggedIn() else {
            return nil
        }

        return TracksUser(userID: ServerSettings.userId, email: ServerSettings.syncingEmail(), username: nil)
    }

    var buildType: String {
    #if STAGING
        return "staging"
    #elseif DEBUG
        return "debug"
    #else
        return "appStore"
    #endif
    }
}
