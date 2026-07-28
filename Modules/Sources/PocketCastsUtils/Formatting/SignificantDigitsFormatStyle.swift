import Foundation

/// A format style for trimming a TimeInterval to Significant Digits
public struct SignificantDigitsFormatStyle: FormatStyle {
    public let significantDigits: Int

    public init(significantDigits: Int) {
        self.significantDigits = significantDigits
    }

    public func format(_ value: TimeInterval) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = significantDigits
        formatter.maximumSignificantDigits = significantDigits
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    public func parse(_ value: String) throws -> Double {
        guard let number = TimeInterval(value) else {
            throw FormatError.invalidInput
        }
        return number
    }

    public enum FormatError: Error {
        case invalidInput
    }
}
