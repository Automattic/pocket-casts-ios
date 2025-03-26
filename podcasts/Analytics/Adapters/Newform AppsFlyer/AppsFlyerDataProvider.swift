import PocketCastsServer

struct AppsFlyerDataProvider: AnonymousIdentifiable {
    let devKey = ApiCredentials.appsFlyerDevKey
    let appleAppID = "PZYM8XX95Q"
    let userDefaults: UserDefaults

    var anonymousUUID: String {
        generateAnonymousUUID()
    }

    init(
        userDefaults: UserDefaults? = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId)
    ) {
        self.userDefaults = userDefaults ?? .standard
    }
}
