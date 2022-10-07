import Foundation
import UIKit

public extension UIFont {
    static func systemFontWithMonospacedNumbers(_ size: CGFloat) -> UIFont {
        let features = [
            [
                UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
                UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector
            ]
        ]

        let fontDescriptor = UIFont.systemFont(ofSize: size).fontDescriptor.addingAttributes(
            [UIFontDescriptor.AttributeName.featureSettings: features]
        )

        return UIFont(descriptor: fontDescriptor, size: size)
    }

    func monospaced() -> UIFont {
        let fontDescriptorFeatureSettings = [
            [
                UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
                UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector
            ]
        ]

        let fontDescriptorAttributes = [UIFontDescriptor.AttributeName.featureSettings: fontDescriptorFeatureSettings]
        let fontDescriptor = fontDescriptor.addingAttributes(fontDescriptorAttributes)

        return UIFont(descriptor: fontDescriptor, size: pointSize)
    }
}
