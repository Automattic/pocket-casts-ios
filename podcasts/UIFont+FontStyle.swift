import UIKit
import SwiftUI

extension UIFont {
    /// Returns a dynamically sizing font with a custom TextStyle and Weight, and is scaled based off the default size category (large)
    static func font(with style: UIFont.TextStyle,
                     weight: UIFont.Weight = .regular,
                     maxSizeCategory: UIContentSizeCategory = .accessibilityExtraExtraExtraLarge) -> UIFont {
        let defaultPointSize = pointSize(for: style, sizeCategory: .large)
        return font(ofSize: defaultPointSize, weight: weight, scalingWith: style, maxSizeCategory: maxSizeCategory)
    }

    /// Returns a dynamically sizing font based of the given defaultSize for the specified `UIFont.TextStyle` and `UIFont.Weight`
    ///
    /// When the current size category is set to the default (.large) the font will be set to `size` and as the size category changes it will be scaled your custom size and the `scalingStyle`.
    ///
    /// Example: Starting at the .large size category, a .body `TextStyle`, will have a pointSize of 17, and will scale to 19, 21, and 23 as the size category increases.
    ///
    /// However if you specified 18 as the default size, then its scale, from .large, would be: 18, 20, 22, and 23 at the largest size category `.accessibilityExtraExtraExtraLarge`
    ///
    /// - Parameters:
    ///   - size: The base font size to use for the font
    ///   - scalingStyle: The `UIFont.TextStyle` to scale the font with
    ///   - weight: The `UIFont.Weight` to use
    ///   - maxSize: When the `maxSize` category is set, the max font size will be limited to this category.
    static func font(ofSize size: CGFloat,
                     weight: UIFont.Weight = .regular,
                     scalingWith style: UIFont.TextStyle,
                     maxSizeCategory: UIContentSizeCategory = .accessibilityExtraExtraExtraLarge) -> UIFont {
        // Get the basic system font for the given size and weight that we can scale from
        let font = systemFont(ofSize: size, weight: weight)

        // Setup the metrics for the font style we'll scale with
        let metrics = UIFontMetrics(forTextStyle: style)

        // Scale the given point size up to the largest size category that we'll allow
        let maxPointSize = metrics.scaledValue(for: size, compatibleWith: UITraitCollection(preferredContentSizeCategory: maxSizeCategory))

        return metrics.scaledFont(for: font, maximumPointSize: maxPointSize)
    }

    /// Calculates the point size for a font style with the specified size category
    static func pointSize(for style: UIFont.TextStyle, sizeCategory: UIContentSizeCategory) -> CGFloat {
        let traits = UITraitCollection(preferredContentSizeCategory: sizeCategory)
        return UIFontDescriptor.preferredFontDescriptor(withTextStyle: style, compatibleWith: traits).pointSize
    }
}

// MARK: - SwiftUI Support

public extension View {
    func font(size: Double? = nil,
              style: Font.TextStyle,
              weight: Font.Weight = .regular,
              maxSizeCategory: UIContentSizeCategory = .extraExtraLarge) -> some View {
        return modifier(DynamicallyScalableFont(size: size, style: style, weight: weight, maxSizeCategory: maxSizeCategory))
    }
}

private struct DynamicallyScalableFont: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory

    var size: Double?
    var style: Font.TextStyle
    var weight: Font.Weight = .regular
    var maxSizeCategory: UIContentSizeCategory = .accessibilityExtraExtraExtraLarge

    func body(content: Content) -> some View {
        // Setup the metrics for the font style we'll scale with
        let metrics = UIFontMetrics(forTextStyle: style.UIFontTextStyle)
        let traits = sizeCategory.traitCollection
        let size = self.size ?? UIFont.pointSize(for: style.UIFontTextStyle, sizeCategory: UIContentSizeCategory.large)

        // Scale the given point size up to the largest size that we'll allow
        let maxPointSize = metrics.scaledValue(for: size, compatibleWith: UITraitCollection(preferredContentSizeCategory: maxSizeCategory))

        // Scale the point size to the current size category, then limit it to the maximum point size
        let scaledSize = min(maxPointSize, metrics.scaledValue(for: size, compatibleWith: traits))

        // Return the new calculated font
        return content.font(.system(size: scaledSize, weight: weight))
    }
}

// MARK: - Enums to map SwiftUI -> UIKit font types

private extension ContentSizeCategory {
    var traitCollection: UITraitCollection {
        UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory)
    }

    var UIContentSizeCategory: UIContentSizeCategory {
        switch self {
        case .extraSmall:
            return .extraSmall
        case .small:
            return .small
        case .medium:
            return .medium
        case .large:
            return .large
        case .extraLarge:
            return .extraLarge
        case .extraExtraLarge:
            return .extraExtraLarge
        case .extraExtraExtraLarge:
            return .extraExtraExtraLarge
        case .accessibilityMedium:
            return .accessibilityMedium
        case .accessibilityLarge:
            return .accessibilityLarge
        case .accessibilityExtraLarge:
            return .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge:
            return .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge:
            return .accessibilityExtraExtraLarge
        @unknown default:
            return .large
        }
    }
}

private extension Font.TextStyle {
    var UIFontTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle:
            return .largeTitle
        case .title:
            return .title1
        case .title2:
            return .title2
        case .title3:
            return .title3
        case .headline:
            return .headline
        case .subheadline:
            return .subheadline
        case .body:
            return .body
        case .callout:
            return .callout
        case .footnote:
            return .footnote
        case .caption:
            return .caption1
        case .caption2:
            return .caption2
        @unknown default:
            return .body
        }
    }
}
