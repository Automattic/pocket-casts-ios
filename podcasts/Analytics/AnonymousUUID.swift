import Foundation

enum AnonymousUUID {
    static func generate(userDefaults: UserDefaults) -> String {
        let key = "TracksAnonymousUUID"

        // Generate a new UUID if there isn't currently one
        guard let uuid = userDefaults.string(forKey: key) else {
            // Check the old standard UserDefaults so we don't lose that one
            if let oldUuid = UserDefaults.standard.string(forKey: key) {
                userDefaults.set(oldUuid, forKey: key)
                return oldUuid
            }
            let uuid = UUID().uuidString
            userDefaults.set(uuid, forKey: key)
            return uuid
        }
        return uuid
    }
}
