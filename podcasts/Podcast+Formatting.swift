import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension Podcast {
    func displayableFrequency() -> String? {
        guard let frequency = episodeFrequency?.lowercased(), frequency != "unknown", frequency != "new" else { return nil }

        // the above is in English, from the server unfortunately, so we need to translate it client side
        if frequency == "hourly" {
            return L10n.releaseFrequencyHourly.localizedCapitalized
        } else if frequency == "daily" {
            return L10n.releaseFrequencyDaily.localizedCapitalized
        } else if frequency == "weekly" {
            return L10n.releaseFrequencyWeekly.localizedCapitalized
        } else if frequency == "fortnightly" {
            return L10n.releaseFrequencyFortnightly.localizedCapitalized
        } else if frequency == "monthly" {
            return L10n.releaseFrequencyMonthly.localizedCapitalized
        }

        // we shouldn't get here, but if we do, just return the English string
        return frequency.localizedCapitalized
    }

    func displayableExpiryLanguage(expiryDate: Date) -> String {
        let dateStr = DateFormatHelper.sharedHelper.longLocalizedFormat(expiryDate)

        if licensing == PodcastLicensing.deleteEpisodesAfterExpiry.rawValue {
            return expiryDate.timeIntervalSinceNow < 0 ? L10n.podcastAccessEnded(dateStr) : L10n.podcastAccessEnds(dateStr)
        } else {
            return expiryDate.timeIntervalSinceNow < 0 ? L10n.podcastUpdatesEnded(dateStr) : L10n.podcastUpdatesEnds(dateStr)
        }
    }

    func displayableNextEpisodeDate() -> String? {
        guard let nextEpisodeAt = estimatedNextEpisode else { return nil }

        return simplifiedFutureDate(nextEpisodeAt)
    }

    private func simplifiedFutureDate(_ expectedDate: Date) -> String? {
        if expectedDate.timeIntervalSince1970 <= 0 { return nil }

        let now = Date()

        if expectedDate < now.addingTimeInterval(-7.days) {
            return nil
        } else if Calendar.current.isDateInToday(expectedDate) {
            return L10n.today
        } else if Calendar.current.isDateInTomorrow(expectedDate) {
            return L10n.podcastTomorrow
        } else if expectedDate < now, expectedDate >= now.addingTimeInterval(-7.days) {
            return L10n.podcastSoon
        } else if expectedDate < now.addingTimeInterval(6.days) {
            let dateFormatter = DateFormatHelper.sharedHelper.justDayFormatter
            return dateFormatter.string(from: expectedDate).localizedCapitalized
        } else {
            return DateFormatHelper.sharedHelper.tinyLocalizedFormat(expectedDate)
        }
    }

    #if !os(watchOS)
        func iconTintColor(for theme: Theme.ThemeType? = nil) -> UIColor {
            let theme = theme ?? Theme.sharedTheme.activeTheme
            let podcastColor = theme.isDark ? ColorManager.darkThemeTintForPodcast(self) : ColorManager.lightThemeTintForPodcast(self)

            return ThemeColor.podcastIcon02(podcastColor: podcastColor, for: theme)
        }

        func navigationBarTintColor(for theme: Theme.ThemeType? = nil) -> UIColor {
            let theme = theme ?? Theme.sharedTheme.activeTheme
            let podcastColor = theme.isDark ? ColorManager.darkThemeTintForPodcast(self) : ColorManager.lightThemeTintForPodcast(self)

            return ThemeColor.podcastUi01(podcastColor: podcastColor, for: theme)
        }

        func switchTintColor() -> UIColor {
            let podcastColor = Theme.isDarkTheme() ? ColorManager.darkThemeTintForPodcast(self, defaultColor: AppTheme.switchDarkThemeDefaultColor()) : ColorManager.lightThemeTintForPodcast(self)

            return ThemeColor.podcastIcon02(podcastColor: podcastColor)
        }

        func navIconTintColor() -> UIColor {
            let podcastColor = Theme.isDarkTheme() ? ColorManager.darkThemeTintForPodcast(self) : ColorManager.lightThemeTintForPodcast(self)

            return ThemeColor.podcastIcon01(podcastColor: podcastColor)
        }

        func bgColor() -> UIColor {
            ColorManager.backgroundColorForPodcast(self)
        }
    #endif

    func podcastGrouping() -> PodcastGrouping {
        if FeatureFlag.newSettingsStorage.enabled {
            return settings.episodeGrouping
        } else {
            return PodcastGrouping(rawValue: episodeGrouping) ?? .none
        }
    }
}
