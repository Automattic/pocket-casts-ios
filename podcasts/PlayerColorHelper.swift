import Foundation
import PocketCastsDataModel

struct PlayerColorHelper {
    static func playerBackgroundColor01(for theme: Theme.ThemeType = Theme.sharedTheme.activeTheme,
                                        episode: BaseEpisode? = PlaybackManager.shared.currentEpisode()) -> UIColor {
        guard let podcastBackgroundColor = backgroundColor(for: episode) else { return UIColor.black }

        return ThemeColor.playerBackground01(podcastColor: podcastBackgroundColor, for: theme)
    }

    static func playerBackgroundColor02(for theme: Theme.ThemeType = Theme.sharedTheme.activeTheme,
                                        episode: BaseEpisode? = PlaybackManager.shared.currentEpisode()) -> UIColor {
        guard let podcastBackgroundColor = backgroundColor(for: episode) else { return UIColor.black }

        return ThemeColor.playerBackground02(podcastColor: podcastBackgroundColor, for: theme)
    }

    static func playerHighlightColor01(for theme: Theme.ThemeType,
                                       episode: BaseEpisode? = PlaybackManager.shared.currentEpisode()) -> UIColor {
        guard let podcastColor = tint(for: episode, with: theme) else { return UIColor.white }

        return ThemeColor.playerHighlight01(podcastColor: podcastColor)
    }

    static func playerHighlightColor02(for theme: Theme.ThemeType,
                                       episode: BaseEpisode? = PlaybackManager.shared.currentEpisode()) -> UIColor {
        guard let podcastColor = tint(for: episode, with: theme) else { return UIColor.white }

        return ThemeColor.playerHighlight02(podcastColor: podcastColor)
    }

    static func playerHighlightColor06(for theme: Theme.ThemeType,
                                       episode: BaseEpisode? = PlaybackManager.shared.currentEpisode()) -> UIColor {
        guard let podcastColor = tint(for: episode, with: theme) else { return UIColor.white }

        return ThemeColor.playerHighlight06(podcastColor: podcastColor)
    }

    static func playerHighlightColor07(for theme: Theme.ThemeType,
                                       episode: BaseEpisode? = PlaybackManager.shared.currentEpisode()) -> UIColor {
        guard let podcastColor = tint(for: episode, with: theme) else { return UIColor.white }

        return ThemeColor.playerHighlight07(podcastColor: podcastColor)
    }

    static func podcastInteractive03(for theme: Theme.ThemeType,
                                     episode: BaseEpisode? = PlaybackManager.shared.currentEpisode()) -> UIColor {
        guard let podcastColor = tint(for: episode, with: theme) else { return UIColor.white }

        return ThemeColor.podcastInteractive03(podcastColor: podcastColor)
    }

    static func podcastInteractive04(for theme: Theme.ThemeType,
                                     episode: BaseEpisode? = PlaybackManager.shared.currentEpisode()) -> UIColor {
        guard let podcastColor = tint(for: episode, with: theme) else { return UIColor.white }

        return ThemeColor.podcastInteractive04(podcastColor: podcastColor)
    }

    static func podcastInteractive05(for theme: Theme.ThemeType,
                                     episode: BaseEpisode? = PlaybackManager.shared.currentEpisode()) -> UIColor {
        guard let podcastColor = tint(for: episode, with: theme) else { return UIColor.white }

        return ThemeColor.podcastInteractive05(podcastColor: podcastColor)
    }

    private static func tint(for episode: BaseEpisode?, with theme: Theme.ThemeType) -> UIColor? {
        if let userEpisode = episode as? UserEpisode {
            return userEpisode.imageColor > 0 ? AppTheme.userEpisodeColor(number: Int(userEpisode.imageColor)) : AppTheme.userEpisodeNoArtworkColor()
        }

        guard let parentPodcast = (episode as? Episode)?.parentPodcast() else {
            return nil
        }

        return theme.isDark ? ColorManager.darkThemeTintForPodcast(parentPodcast) : ColorManager.lightThemeTintForPodcast(parentPodcast)
    }

    private static func backgroundColor(for episode: BaseEpisode?) -> UIColor? {
        guard let parentPodcast = (episode as? Episode)?.parentPodcast() else {
            return nil
        }

        return ColorManager.backgroundColorForPodcast(parentPodcast)
    }
}
