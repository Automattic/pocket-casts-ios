import Foundation
import UIKit

public extension UIFont {
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
