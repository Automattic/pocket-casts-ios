import Foundation
import SwiftUI

class WidgetEpisode: ObservableObject, Hashable {
    @Published var episodeUuid: String
    @Published var episodeTitle: String
    @Published var podcastName: String
    @Published var podcastColor: String
    @Published var duration: TimeInterval
    @Published var imageData: Data?

    private var imageUrl: URL?

    init(commonItem: CommonUpNextItem) {
        episodeTitle = commonItem.episodeTitle
        episodeUuid = commonItem.episodeUuid
        duration = commonItem.duration
        podcastName = commonItem.podcastName
        podcastColor = commonItem.podcastColor
        imageUrl = urlForItem(commonItem)
    }

    // in a widget, you can't load images asynchronously, since the UI is rendered and later displayed, so as weird as it looks, this is how we cache the image data
    func loadImageData() {
        guard let imageUrl = imageUrl else { return }

        imageData = try? Data(contentsOf: imageUrl)
    }

    static func == (lhs: WidgetEpisode, rhs: WidgetEpisode) -> Bool {
        lhs.episodeUuid == rhs.episodeUuid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(episodeUuid)
    }

    private func urlForItem(_ commonItem: CommonUpNextItem) -> URL? {
        if commonItem.imageUrl.hasPrefix("http") {
            return URL(string: commonItem.imageUrl)
        } else {
            let fileManager = FileManager.default
            let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: CommonWidgetHelper.appGroupId)
            if let container = container {
                let directoryPath = container.appendingPathComponent("widget_images")
                let sharedFilePath = directoryPath.appendingPathComponent("\(commonItem.episodeUuid).jpg")
                if fileManager.fileExists(atPath: sharedFilePath.path) {
                    return sharedFilePath
                }
            }

            return nil
        }
    }
}
