import Foundation
import PocketCastsDataModel
import PocketCastsUtils
#if !os(watchOS)
    import UIKit
#endif

#if os(watchOS)
    import WatchKit
#endif

struct EpisodeDateHelper {
    private static func seasonTrailerText(_ seasonNumber: Int64) -> String {
        seasonNumber > 0 ? L10n.episodeIndicatorSeasonTrailer(seasonNumber.localized()) : L10n.episodeIndicatorTrailer
    }

    #if !os(watchOS)
        static func setDate(episode: BaseEpisode, on label: UILabel, tintColor: UIColor?) {
            let episodeDate = DateFormatHelper.sharedHelper.tinyLocalizedFormat(episode.publishedDate).localizedUppercase

            guard let episode = episode as? Episode else {
                label.text = episodeDate

                return
            }

            if episode.isBonus() {
                setRowTitle(dateText: episodeDate, episode: episode, label: label, tintColor: tintColor, indicatorText: L10n.episodeIndicatorBonus.localizedUppercase)
            } else if episode.isTrailer() {
                let indicator = seasonTrailerText(episode.seasonNumber).localizedUppercase
                setRowTitle(dateText: episodeDate, episode: episode, label: label, tintColor: tintColor, indicatorText: indicator)
            } else {
                setRowTitle(dateText: episodeDate, episode: episode, label: label, tintColor: tintColor)
            }
        }

        static func formattedDate(for episode: BaseEpisode) -> String {
            let episodeDate = DateFormatHelper.sharedHelper.tinyLocalizedFormat(episode.publishedDate).localizedUppercase

            guard let episode = episode as? Episode else {
                return episodeDate
            }
            if episode.isBonus() {
                return rowTitle(dateText: episodeDate, episode: episode, indicatorText: L10n.episodeIndicatorBonus.localizedUppercase)
            } else if episode.isTrailer() {
                let indicator = seasonTrailerText(episode.seasonNumber).localizedUppercase
                return rowTitle(dateText: episodeDate, episode: episode, indicatorText: indicator)
            } else {
                return rowTitle(dateText: episodeDate, episode: episode)
            }
        }

        private static func rowTitle(dateText: String, episode: Episode, indicatorText: String? = nil) -> String {
            guard let indicatorText = indicatorText else {
                if episode.episodeNumber < 1 {
                    return dateText
                }
                let prefix = L10n.seasonEpisodeShorthand(seasonNumber: episode.seasonNumber, episodeNumber: episode.episodeNumber)
                return "\(prefix) • \(dateText)"
            }
            return "\(indicatorText) • \(dateText)"
        }

        private static func setRowTitle(dateText: String, episode: Episode, label: UILabel, tintColor: UIColor?, indicatorText: String? = nil) {
            guard let indicatorText = indicatorText, let tintColor = tintColor else {
                if episode.episodeNumber < 1 {
                    label.text = dateText

                    return
                }

                let prefix = L10n.seasonEpisodeShorthand(seasonNumber: episode.seasonNumber, episodeNumber: episode.episodeNumber)
                label.text = "\(prefix) • \(dateText)"

                return
            }

            let attributedString = NSMutableAttributedString(string: "\(indicatorText) • \(dateText)")
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: tintColor, range: NSRange(location: 0, length: indicatorText.count))
            label.attributedText = attributedString
        }
    #endif

    #if os(watchOS)
        static func setDate(episode: BaseEpisode, on label: WKInterfaceLabel) {
            let episodeDate = displayDate(forEpisode: episode)
            label.setText(episodeDate)
        }

        static func displayDate(forEpisode episode: BaseEpisode) -> String {
            let episodeDate = DateFormatHelper.sharedHelper.tinyLocalizedFormat(episode.publishedDate)

            guard let episode = episode as? Episode else {
                return episodeDate
            }

            if episode.isBonus() {
                return rowTitle(dateText: episodeDate, episode: episode, indicatorText: L10n.episodeIndicatorBonus)
            } else if episode.isTrailer() {
                let indicator = seasonTrailerText(episode.seasonNumber)
                return rowTitle(dateText: episodeDate, episode: episode, indicatorText: indicator)
            }

            return rowTitle(dateText: episodeDate, episode: episode)
        }

        private static func rowTitle(dateText: String, episode: Episode, indicatorText: String? = nil) -> String {
            guard let indicatorText = indicatorText else {
                if episode.episodeNumber < 1 {
                    return dateText
                }

                let prefix = L10n.seasonEpisodeShorthand(seasonNumber: episode.seasonNumber, episodeNumber: episode.episodeNumber)
                return "\(prefix) • \(dateText)"
            }

            return "\(indicatorText) • \(dateText)"
        }
    #endif
}
