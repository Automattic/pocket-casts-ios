import CoreGraphics
import Foundation

// MARK: - Numbers

public extension Int {
    func localized(_ style: NumberFormatter.Style = .none) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: self), number: style)
    }
}

public extension Int32 {
    func localized(_ style: NumberFormatter.Style = .none) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: self), number: style)
    }
}

public extension Int64 {
    func localized(_ style: NumberFormatter.Style = .none) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: self), number: style)
    }
}

public extension Double {
    func localized(_ style: NumberFormatter.Style = .decimal) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: self), number: style)
    }
}

public extension CGFloat {
    func localized(_ style: NumberFormatter.Style = .decimal) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: self), number: style)
    }
}
