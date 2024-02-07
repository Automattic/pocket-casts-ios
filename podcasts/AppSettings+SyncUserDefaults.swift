import PocketCastsServer
import PocketCastsUtils

extension SettingsStore<AppSettings> {
    /// Updates the values in AppSettings with
    /// - Parameter userDefaults: The UserDefaults to read values from
    func importUserDefaults(_ userDefaults: UserDefaults = UserDefaults.standard) {
        self.update(\.$openLinks, value: userDefaults.bool(forKey: Constants.UserDefaults.openLinksInExternalBrowser))
        self.update(\.$rowAction, value: Int32(UserDefaults.standard.integer(forKey: "SJRowAction")))
    }
}
