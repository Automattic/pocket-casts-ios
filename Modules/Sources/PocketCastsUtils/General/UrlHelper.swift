import Foundation

public struct URLHelper {
    public static func isValidScheme(_ scheme: String?) -> Bool {
        guard let scheme else { return false }

        return ((scheme.caseInsensitiveCompare("http") == .orderedSame) || (scheme.caseInsensitiveCompare("https") == .orderedSame))
    }

    public static func isMailtoScheme(_ scheme: String?) -> Bool {
        guard let scheme else { return false }

        return scheme.caseInsensitiveCompare("mailto") == .orderedSame
    }
}
