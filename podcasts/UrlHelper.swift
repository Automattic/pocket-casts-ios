import Foundation

struct URLHelper {
    static func isValidScheme(_ scheme: String?) -> Bool {
        guard let scheme = scheme else { return false }

        return ((scheme.caseInsensitiveCompare("http") == .orderedSame) || (scheme.caseInsensitiveCompare("https") == .orderedSame))
    }

    static func isMailtoScheme(_ scheme: String?) -> Bool {
        guard let scheme = scheme else { return false }

        return scheme.caseInsensitiveCompare("mailto") == .orderedSame
    }
}
