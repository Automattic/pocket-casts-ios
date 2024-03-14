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

    init(episode: BaseEpisode) {
        super.init(episode: episode, skipHydration: true)
    }

    override func hydrate() {
        if alreadyHydrated {
            return
        }
        super.hydrate()

        updateProperties(episode: episode, downloadProgress: downloadProgress)
        Publishers.CombineLatest($episode, $downloadProgress)
            .receive(on: RunLoop.main)
            .dropFirst()
            .sink(receiveValue: { [unowned self] episode, downloadProgress in
                updateProperties(episode: episode, downloadProgress: downloadProgress)
            })
            .store(in: &cancellables)
    }

    private func updateProperties(episode: BaseEpisode, downloadProgress: DownloadProgress?) {
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
        switch DownloadStatus(rawValue: episode.episodeStatus) {
        case .downloaded:
            self.downloadStatusIconName = "episodedownloaded"
            info = episode.displayableTimeLeft()
            statusText = L10n.statusDownloaded
        case .downloading:
            self.downloadStatusIconName = nil
            info = episode.displayableInfo(includeSize: false)
            statusText = L10n.statusDownloading
        case .downloadFailed:
            self.downloadStatusIconName = "downloadfailed"
            informationLabel = []
            accessibilityLabel = [L10n.downloadFailed]
            info = episode.displayableInfo(includeSize: false)
            statusText = nil
        default:
            self.downloadStatusIconName = nil
            info = episode.displayableInfo(includeSize: false)
            statusText = L10n.statusNotDownloaded
        }

        informationLabel.append(info)
        accessibilityLabel.append(info)

        if let statusText = statusText {
            accessibilityLabel.append(statusText)
        }

        self.displayInfo = informationLabel.joined(separator: " • ")
        self.accessibilityInfo = accessibilityLabel.joined(separator: " , ")
    }
}
