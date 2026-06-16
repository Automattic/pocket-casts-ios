import SwiftUI
import PocketCastsUtils

enum ExplicitBadgeHelper {

    static let badgeFontSize: CGFloat = 8
    static var badgeSize: CGFloat {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)
        let fontSize = metric.scaledValue(for: badgeFontSize)
        return fontSize * 1.5
    }

    private static var imageCache: [Theme.ThemeType: UIImage] = [:]
    private static var cacheSize = CGFloat(badgeFontSize)

    static func badgeImage(for theme: Theme.ThemeType? = nil, fontSize: CGFloat = badgeFontSize) -> UIImage {
        if cacheSize != fontSize {
            cacheSize = fontSize
            imageCache.removeAll()
        }
        let resolvedTheme = theme ?? Theme.sharedTheme.activeTheme
        if let cached = imageCache[resolvedTheme] {
            return cached
        }
        let image = renderBadgeImage(for: resolvedTheme, fontSize: fontSize)
        imageCache[resolvedTheme] = image
        return image
    }

    private static func renderBadgeImage(for theme: Theme.ThemeType, fontSize: CGFloat = badgeFontSize) -> UIImage {
        let bgColor = ThemeColor.primaryIcon03(for: theme)
        let badgeSize = fontSize * 1.5
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: badgeSize, height: badgeSize))
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: CGSize(width: badgeSize, height: badgeSize))
            bgColor.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 2).fill()

            let text = "E" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .heavy),
                .foregroundColor: UIColor.white,
            ]
            let textSize = text.size(withAttributes: attrs)
            let textRect = CGRect(
                x: (badgeSize - textSize.width) / 2,
                y: (badgeSize - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attrs)
        }
    }

    static func inlineTitle(_ title: String, isExplicit: Bool, theme: Theme.ThemeType? = nil) -> Text {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)
        let fontSize = metric.scaledValue(for: badgeFontSize)
        if FeatureFlag.showExplicitBadges.enabled, isExplicit {
            return Text(title) + Text(" ") + Text(Image(uiImage: badgeImage(for: theme, fontSize: fontSize))).baselineOffset(-1).accessibilityLabel(L10n.podcastExplicitContent)
        }
        return Text(title)
    }

    static func attributedTitle(_ title: String, font: UIFont, theme: Theme.ThemeType? = nil) -> NSAttributedString {
        guard FeatureFlag.showExplicitBadges.enabled else {
            return NSAttributedString(string: title, attributes: [.font: font])
        }
        let result = NSMutableAttributedString(string: title + " ", attributes: [.font: font])

        let metric = UIFontMetrics(forTextStyle: .largeTitle)
        let fontSize = metric.scaledValue(for: badgeFontSize)
        let badgeSize = fontSize * 1.5

        let image = badgeImage(for: theme, fontSize: fontSize)
        let attachment = NSTextAttachment()
        attachment.image = image
        let yOffset = (font.capHeight - badgeSize) / 2
        attachment.bounds = CGRect(x: 0, y: yOffset, width: badgeSize, height: badgeSize)
        result.append(NSAttributedString(attachment: attachment))

        return result
    }
}
