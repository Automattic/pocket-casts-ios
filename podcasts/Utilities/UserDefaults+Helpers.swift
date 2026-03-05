import Foundation

extension UserDefaults {
    @objc dynamic var debugOptedOut: Bool {
        get {
            bool(forKey: Constants.UserDefaults.supportRemoveDebugInfo)
        }
        set {
            set(newValue, forKey: Constants.UserDefaults.supportRemoveDebugInfo)
        }
    }
}
