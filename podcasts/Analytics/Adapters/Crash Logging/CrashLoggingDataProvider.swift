import Foundation
import AutomatticRemoteLogging

class CrashLoggingDataProvider: AutomatticRemoteLogging.CrashLoggingDataProvider {
    let sentryDSN = ApiCredentials.sentryDSN
    let userHasOptedOut = false
    let shouldEnableAutomaticSessionTracking = true
    var currentUser: AutomatticTracksModel.TracksUser? = nil

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
