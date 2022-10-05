import Foundation
import AutomatticRemoteLogging

class CrashLoggingDataProvider: AutomatticRemoteLogging.CrashLoggingDataProvider {
    let sentryDSN = ApiCredentials.sentryDSN
    var userHasOptedOut: Bool {
        Settings.analyticsOptOut()
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

    var currentUser: AutomatticTracksModel.TracksUser? = nil

    var shouldEnableAutomaticSessionTracking: Bool {
        !userHasOptedOut
    }
}
