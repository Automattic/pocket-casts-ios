import Foundation
import UIKit

public extension String {
    func trim() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func startsWith(string: String?) -> Bool {
        guard let string = string else { return false }

        guard let range = range(of: string, options: .caseInsensitive) else { return false }

        return range.lowerBound == string.startIndex
    }

    func toDouble() -> Double {
        (self as NSString).doubleValue
    }

    func toInt() -> Int {
        Int(self) ?? 0
    }

    func stringByRemovingEmoji() -> String {
        String(filter { !$0.isEmoji() })
    }

    var digits: Int {
        let numberStr = components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        return numberStr.toInt()
    }

    var isValidEmail: Bool {
        /// This implementation is ported directly from https://www.swiftbysundell.com/articles/validating-email-addresses/
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return false
        }

        let range = NSRange(startIndex ..< endIndex, in: self)
        let matches = detector.matches(in: self, options: [], range: range)

        guard let match = matches.first, matches.count == 1 else {
            return false
        }

        // Verify that the found link points to an email address and that its range covers the whole input string:
        guard match.url?.scheme == "mailto", match.range == range else {
            return false
        }

        return true
    }

    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]

        let attributedSize = self.size(withAttributes: fontAttributes)

        return attributedSize.width
    }

    /// Returns a lowercased copy of the string with punctuation removed and spaces replaced
    /// by a single underscore, e.g., "the_quick_brown_fox_jumps_over_the_lazy_dog".
    func lowerSnakeCased() -> String {
        return enumerated().map { index, character in
            character.isUppercase ? "_\(character.lowercased())" : "\(character)"
        }.joined()
    }
}
