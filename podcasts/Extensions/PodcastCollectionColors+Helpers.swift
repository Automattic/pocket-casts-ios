import PocketCastsServer
import UIKit

extension PodcastCollectionColors {
    var activeThemeColor: UIColor? {
        guard let darkColor = onDarkBackground, let lightColor = onLightBackground else {
            return nil
        }
        let hexCode = Theme.isDarkTheme() ? darkColor : lightColor
        return hexCode.isEmpty ? nil : UIColor(hex: hexCode)
    }
}
