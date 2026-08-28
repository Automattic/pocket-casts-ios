import PocketCastsServer
import UIKit

extension PodcastCollectionColors {
    /// The color for the current theme, or `nil` when the collection came without a usable one.
    var activeThemeColor: UIColor? {
        guard let darkColor = onDarkBackground, let lightColor = onLightBackground else {
            return nil
        }
        return UIColor.from(hex: Theme.isDarkTheme() ? darkColor : lightColor)
    }
}
