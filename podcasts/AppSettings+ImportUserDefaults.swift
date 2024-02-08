import PocketCastsServer
import PocketCastsUtils

extension SettingsStore<AppSettings> {
    /// Updates the values in AppSettings with
    /// - Parameter userDefaults: The UserDefaults to read values from
    func importUserDefaults(_ userDefaults: UserDefaults = UserDefaults.standard) {
        self.update(\.$openLinks, value: userDefaults.bool(forKey: Constants.UserDefaults.openLinksInExternalBrowser))
        self.update(\.$rowAction, value: Int32(UserDefaults.standard.integer(forKey: "SJRowAction")))
        self.update(\.$skipForward, value: Int32(ServerSettings.skipForwardTime()))
        self.update(\.$skipBack , value: Int32(ServerSettings.skipBackTime()))
        self.update(\.$keepScreenAwake , value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.keepScreenOnWhilePlaying))
        self.update(\.$openPlayer , value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.openPlayerAutomatically))
        self.update(\.$intelligentResumption, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.intelligentPlaybackResumption))
    }
}
