import SwiftUI
import PocketCastsDataModel

/// Given a podcast, check if the colors contrast is good
/// If not, return default hardcoded colors.
struct CategoriesContrastingColors {
    let backgroundColor: Color
    let foregroundColor: Color
    let tintColor: Color

    init(podcast: Podcast) {
        let backgroundColorForPodcast = ColorManager.backgroundColorForPodcast(podcast).color
        let darkThemeTintForPodcast = ColorManager.darkThemeTintForPodcast(podcast).color
        let lightThemeTintForPodcast = ColorManager.lightThemeTintForPodcast(podcast).color

        if backgroundColorForPodcast.contrast(with: darkThemeTintForPodcast) > 2 {
            backgroundColor = backgroundColorForPodcast
            foregroundColor = lightThemeTintForPodcast
            tintColor = darkThemeTintForPodcast
        } else {
            backgroundColor = UIColor(hex: "#744F9D").color
            foregroundColor = UIColor(hex: "#301E3E").color
            tintColor = UIColor(hex: "#FE7E61").color
        }
    }
}
