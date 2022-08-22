import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension BaseEpisode {
    func fileExtension() -> String {
        FileTypeUtil.fileExtension(forType: fileType)
    }
    
    func readableErrorMessage() -> String {
        guard let details = downloadErrorDetails else {
            return L10n.Localizable.podcastFailedDownload
        }
        
        return details
    }
    
    func displayableTimeLeft() -> String {
        if inProgress(), playedUpTo > 0, duration > 0 {
            if duration > playedUpTo {
                let time = TimeFormatter.shared.multipleUnitFormattedShortTime(time: duration - playedUpTo)
                return L10n.Localizable.podcastTimeLeft(time)
            }
            else {
                return TimeFormatter.shared.multipleUnitFormattedShortTime(time: 0)
            }
        }
        
        return TimeFormatter.shared.multipleUnitFormattedShortTime(time: duration)
    }
    
    func commonDisplayableInfo(includeSize: Bool) -> String {
        if downloading() {
            if let progress = DownloadManager.shared.progressManager.progressForEpisode(uuid) {
                #if os(watchOS)
                    return "\(progress.percentageProgressAsString())"
                #else
                    return L10n.Localizable.podcastDownloading(progress.percentageProgressAsString())
                #endif
            }
            else {
                return L10n.Localizable.podcastDownloading("").trimmingCharacters(in: .whitespaces)
            }
        }
        else if queued() {
            if sizeInBytes > 0 {
                let size = SizeFormatter.shared.noDecimalFormat(bytes: sizeInBytes)
                return L10n.Localizable.podcastQueued + " • " + size
            }
            else {
                return L10n.Localizable.podcastQueuing
            }
        }
        else if let playbackError = playbackErrorDetails {
            return playbackError
        }
        else if downloadFailed() {
            return readableErrorMessage()
        }
        else {
            var informationLabelStr = duration > 0 ? displayableTimeLeft() : L10n.Localizable.unknownDuration
            
            if includeSize, sizeInBytes > 0 {
                if informationLabelStr.count == 0 {
                    informationLabelStr = SizeFormatter.shared.noDecimalFormat(bytes: sizeInBytes)
                }
                else {
                    informationLabelStr += " • \(SizeFormatter.shared.noDecimalFormat(bytes: sizeInBytes))"
                }
            }
            
            return informationLabelStr
        }
    }

    func displayableInfo(includeSize: Bool = true) -> String {
        commonDisplayableInfo(includeSize: includeSize)
    }
    
    func shortPublishedDate() -> String {
        shortDateFor(date: publishedDate)
    }
    
    func shortLastDownloadAttemptDate() -> String {
        shortDateFor(date: lastDownloadAttemptDate)
    }
    
    func shortDateFor(date: Date?) -> String {
        let noDate = L10n.Localizable.podcastNoDate
        guard let date = date, date.timeIntervalSince1970 > 0 else { return noDate }
        
        if Calendar.current.isDateInToday(date) {
            return L10n.Localizable.today
        }
        else if Calendar.current.isDateInYesterday(date) {
            return L10n.Localizable.podcastYesterday
        }
        
        let calendar = Calendar.current
        let publishedMonth = calendar.component(.month, from: date)
        let now = Date()
        
        var shortDate: String?
        if calendar.isDate(now, equalTo: date, toGranularity: .year) {
            let currentMonth = calendar.component(.month, from: now)
            
            if currentMonth == publishedMonth {
                shortDate = L10n.Localizable.podcastThisMonth
            }
            else {
                shortDate = calendar.monthSymbols[publishedMonth - 1]
            }
        }
        else {
            shortDate = DateFormatHelper.sharedHelper.monthYearFormatter.string(from: date)
        }
        
        return shortDate ?? noDate
    }
    
    func subTitle() -> String {
        if let episode = self as? Episode {
            return episode.subTitle()
        }
        else if let episode = self as? UserEpisode {
            return episode.subTitle()
        }
        
        return ""
    }
}
