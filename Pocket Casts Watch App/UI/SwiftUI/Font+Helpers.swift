import Foundation
import SwiftUI

extension Font {
    private static let systemFamilyName = UIFont.systemFont(ofSize: 12).familyName

    public static func dynamic(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(systemFamilyName, size: size).weight(weight)
    }
}
