import Foundation
import PocketCastsDataModel

struct PlayerColorHelper {
    static func playerBackgroundColor01() -> UIColor {
        guard let podcastBackgroundColor = backgroundColorForPlayingEpisode() else { return UIColor.black }

        return ThemeColor.playerBackground01(podcastColor: podcastBackgroundColor)
    }

    static func playerBackgroundColor02() -> UIColor {
        guard let podcastBackgroundColor = backgroundColorForPlayingEpisode() else { return UIColor.black }

        return ThemeColor.playerBackground02(podcastColor: podcastBackgroundColor)
    }

    static func playerHighlightColor01(for theme: Theme.ThemeType) -> UIColor {
        guard let podcastColor = themeTintForPlayingEpisode(for: theme) else { return UIColor.white }

        return ThemeColor.playerHighlight01(podcastColor: podcastColor)
    }

    static func playerHighlightColor02(for theme: Theme.ThemeType) -> UIColor {
        guard let podcastColor = themeTintForPlayingEpisode(for: theme) else { return UIColor.white }

        return ThemeColor.playerHighlight02(podcastColor: podcastColor)
    }

    static func playerHighlightColor06(for theme: Theme.ThemeType) -> UIColor {
        guard let podcastColor = themeTintForPlayingEpisode(for: theme) else { return UIColor.white }

        return ThemeColor.playerHighlight06(podcastColor: podcastColor)
    }

    static func playerHighlightColor07(for theme: Theme.ThemeType) -> UIColor {
        guard let podcastColor = themeTintForPlayingEpisode(for: theme) else { return UIColor.white }

        return ThemeColor.playerHighlight07(podcastColor: podcastColor)
    }

    static func podcastInteractive03(for theme: Theme.ThemeType) -> UIColor {
        guard let podcastColor = themeTintForPlayingEpisode(for: theme) else { return UIColor.white }

        return ThemeColor.podcastInteractive03(podcastColor: podcastColor)
    }

    static func podcastInteractive04(for theme: Theme.ThemeType) -> UIColor {
        guard let podcastColor = themeTintForPlayingEpisode(for: theme) else { return UIColor.white }

        return ThemeColor.podcastInteractive04(podcastColor: podcastColor)
    }

    static func podcastInteractive05(for theme: Theme.ThemeType) -> UIColor {
        guard let podcastColor = themeTintForPlayingEpisode(for: theme) else { return UIColor.white }

        return ThemeColor.podcastInteractive05(podcastColor: podcastColor)
    }

    private static func themeTintForPlayingEpisode(for theme: Theme.ThemeType) -> UIColor? {
        if let episode = PlaybackManager.shared.currentEpisode() as? UserEpisode {
            return episode.imageColor > 0 ? AppTheme.userEpisodeColor(number: Int(episode.imageColor)) : AppTheme.userEpisodeNoArtworkColor()
        }

        guard let episode = PlaybackManager.shared.currentEpisode() as? Episode, let parentPodcast = episode.parentPodcast() else {
            return nil
        }

        return theme.isDark ? ColorManager.darkThemeTintForPodcast(parentPodcast) : ColorManager.lightThemeTintForPodcast(parentPodcast)
    }

    private static func backgroundColorForPlayingEpisode() -> UIColor? {
        guard let episode = PlaybackManager.shared.currentEpisode() as? Episode, let parentPodcast = episode.parentPodcast() else {
            return nil
        }

        return ColorManager.backgroundColorForPodcast(parentPodcast)
    }
}
