import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct ExplicitBadge: View {
    @EnvironmentObject private var theme: Theme

    var body: some View {
        Text("E")
            .font(.system(size: 7, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 11, height: 11)
            .background(AppTheme.color(for: .primaryIcon03, theme: theme))
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .accessibilityLabel(L10n.podcastExplicitContent)
    }
}

enum ExplicitBadgeHelper {
    static let badgeSize: CGFloat = 11

    static func badgeImage(for theme: Theme.ThemeType? = nil) -> UIImage {
        let bgColor = ThemeColor.primaryIcon03(for: theme)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: badgeSize, height: badgeSize))
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: CGSize(width: badgeSize, height: badgeSize))
            bgColor.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 2).fill()

            let text = "E" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 7, weight: .heavy),
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
        if FeatureFlag.showExplicitBadges.enabled, isExplicit {
            return Text(title) + Text(" ") + Text(Image(uiImage: badgeImage(for: theme))).baselineOffset(-1).accessibilityLabel(L10n.podcastExplicitContent)
        }
        return Text(title)
    }

    static func attributedTitle(_ title: String, font: UIFont, theme: Theme.ThemeType? = nil) -> NSAttributedString {
        guard FeatureFlag.showExplicitBadges.enabled else {
            return NSAttributedString(string: title, attributes: [.font: font])
        }
        let result = NSMutableAttributedString(string: title + " ", attributes: [.font: font])
        let image = badgeImage(for: theme)

        let attachment = NSTextAttachment()
        attachment.image = image
        let yOffset = (font.capHeight - badgeSize) / 2
        attachment.bounds = CGRect(x: 0, y: yOffset, width: badgeSize, height: badgeSize)
        result.append(NSAttributedString(attachment: attachment))

        return result
    }
}
