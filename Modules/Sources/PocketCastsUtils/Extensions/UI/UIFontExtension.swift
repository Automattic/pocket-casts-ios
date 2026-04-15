import Foundation
import UIKit

public extension UIFont {
    @available(watchOS 8.0, *)
    static func systemFontWithMonospacedNumbers(_ size: CGFloat) -> UIFont {
        let features = [
            [
                UIFontDescriptor.FeatureKey.selector: kNumberSpacingType,
                UIFontDescriptor.FeatureKey.type: kMonospacedNumbersSelector
            ]
        ]

        let fontDescriptor = UIFont.systemFont(ofSize: size).fontDescriptor.addingAttributes(
            [UIFontDescriptor.AttributeName.featureSettings: features]
        )

        return UIFont(descriptor: fontDescriptor, size: size)
    }

    @available(watchOS 8.0, *)
    func monospaced() -> UIFont {
        let fontDescriptorFeatureSettings = [
            [
                UIFontDescriptor.FeatureKey.selector: kNumberSpacingType,
                UIFontDescriptor.FeatureKey.type: kMonospacedNumbersSelector
            ]
        ]

        let fontDescriptorAttributes = [UIFontDescriptor.AttributeName.featureSettings: fontDescriptorFeatureSettings]
        let fontDescriptor = fontDescriptor.addingAttributes(fontDescriptorAttributes)

        return UIFont(descriptor: fontDescriptor, size: pointSize)
    }
}
