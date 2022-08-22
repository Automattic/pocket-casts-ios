import Combine
import Foundation
import PocketCastsDataModel
import PocketCastsUtils

class EpisodeRowViewModel: EpisodeViewModel, Identifiable {
    var id: String { episode.uuid }

    @Published var displayInfo: String = ""
    @Published var accessibilityInfo: String = ""
    @Published var downloadStatusIconName: String?
    @Published var isDownloading = false

    override init(episode: BaseEpisode) {
        super.init(episode: episode)

        Publishers.CombineLatest($episode, $downloadProgress)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] episode, downloadProgress in
                var informationLabel = [String]()
                var accessibilityLabel = [episode.title ?? ""]

                if let publishedDate = episode.publishedDate {
                    let info = DateFormatHelper.sharedHelper.shortLocalizedFormat(publishedDate)
                    informationLabel.append(info)
                    accessibilityLabel.append(info)
                }

                isDownloading = episode.downloading() || downloadProgress != nil

                let info: String
                let statusText: String?
                switch episode.episodeStatus {
                case DownloadStatus.downloaded.rawValue:
                    self.downloadStatusIconName = "episodedownloaded"
                    info = episode.displayableTimeLeft()
                    statusText = L10n.Localizable.statusDownloaded
                case DownloadStatus.downloading.rawValue:
                    self.downloadStatusIconName = nil
                    info = episode.displayableInfo(includeSize: false)
                    statusText = L10n.Localizable.statusDownloading
                case DownloadStatus.downloadFailed.rawValue:
                    self.downloadStatusIconName = "downloadfailed"
                    informationLabel = []
                    accessibilityLabel = [L10n.Localizable.downloadFailed]
                    info = episode.displayableInfo(includeSize: false)
                    statusText = nil
                default:
                    self.downloadStatusIconName = nil
                    info = episode.displayableInfo(includeSize: false)
                    statusText = L10n.Localizable.statusNotDownloaded
                }

                informationLabel.append(info)
                accessibilityLabel.append(info)

                if let statusText = statusText {
                    accessibilityLabel.append(statusText)
                }

                self.displayInfo = informationLabel.joined(separator: " • ")
                self.accessibilityInfo = accessibilityLabel.joined(separator: " , ")
            })
            .store(in: &cancellables)
    }
}
