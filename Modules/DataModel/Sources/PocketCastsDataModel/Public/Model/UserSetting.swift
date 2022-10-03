import Foundation

public class UserSetting {
    public var name: String = ""
    public var rawValue: String?
    public var modifiedTime: Int64 = 0

    public func boolValue(defaultValue: Bool) -> Bool {
        if let value = rawValue {
            return NSString(string: value).boolValue
        }

        return defaultValue
    }
}
