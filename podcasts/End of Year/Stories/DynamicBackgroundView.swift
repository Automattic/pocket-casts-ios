import SwiftUI
import PocketCastsDataModel

struct DynamicBackgroundView: View {
    @ObservedObject private var model: DynamicBackgroundProvider

    init(podcast: Podcast) {
        model = DynamicBackgroundProvider(podcast: podcast)
    }

    init(backgroundColor: Color, foregroundColor: Color) {
        model = DynamicBackgroundProvider(backgroundColor: backgroundColor, foregroundColor: foregroundColor)
    }

    var body: some View {
        ZStack {
            model.backgroundColor

            Color.black.opacity(0.2)

            VStack {
                Image("top_blob")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color.white)
                    .opacity(0.5)
            }

            VStack {
                Image("bottom_blob")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(model.foregroundColor)
            }

        }
    }
}

@MainActor
class DynamicBackgroundProvider: ObservableObject {
    @Published var backgroundColor: Color
    @Published var foregroundColor: Color

    private let podcast: Podcast?

    init(podcast: Podcast) {
        backgroundColor = podcast.bgColor().color
        foregroundColor = ColorManager.lightThemeTintForPodcast(podcast).color
        self.podcast = podcast

        if !ColorManager.podcastHasBackgroundColor(podcast) {
            _ = ColorManager.backgroundColorForPodcast(podcast)
            NotificationCenter.default.addObserver(self, selector: #selector(podcastColorsLoaded(_:)), name: Constants.Notifications.podcastColorsDownloaded, object: nil)
        }
    }

    init(backgroundColor: Color, foregroundColor: Color) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.podcast = nil
    }

    @objc private func podcastColorsLoaded(_ notification: Notification) {
        guard let uuidLoaded = notification.object as? String else { return }

        if let podcast, uuidLoaded == podcast.uuid {
            podcast.updateColors()
            backgroundColor = podcast.bgColor().color
            foregroundColor = ColorManager.lightThemeTintForPodcast(podcast).color
        }
    }
}

extension Podcast {
    /// Update current Podcast instance with the latest downloaded colors
    func updateColors() {
        guard let podcast = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) else {
            return
        }

        backgroundColor = podcast.backgroundColor
        primaryColor = podcast.primaryColor
        secondaryColor = podcast.secondaryColor
        colorVersion = podcast.colorVersion
        lastColorDownloadDate = podcast.lastColorDownloadDate
    }
}


struct DynamicBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        DynamicBackgroundView(podcast: Podcast.previewPodcast())
    }
}
