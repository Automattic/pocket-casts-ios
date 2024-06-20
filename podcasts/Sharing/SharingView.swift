import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct ShareDestination: Hashable {
    let name: String
    let icon: Image
    let action: (SharingModal.Option) -> Void

    static func ==(lhs: ShareDestination, rhs: ShareDestination) -> Bool {
        lhs.name == rhs.name && lhs.icon == rhs.icon
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    enum Destination: CaseIterable {
        case instagram
        case whatsapp
        case telegram
        case x
        case tumblr

        var name: String {
            switch self {
            case .instagram:
                "Stories"
            case .whatsapp:
                "Whatsapp"
            case .telegram:
                "Telegram"
            case .x:
                "X"
            case .tumblr:
                "Tumblr"
            }
        }

        var icon: Image {
            switch self {
            case .instagram:
                Image("instagram")
            case .whatsapp:
                Image("whatsapp")
            case .telegram:
                Image("telegram")
            case .x:
                Image("x")
            case .tumblr:
                Image("tumblr")
            }
        }

        var isIncluded: Bool {
            return true
        }
    }

    static var apps: [ShareDestination] {
        return Destination.allCases.compactMap({ destination in
            guard destination.isIncluded else { return nil }
            return ShareDestination(name: destination.name, icon: destination.icon, action: { _ in })
        })
    }

    static func moreOption(vc: UIViewController) -> ShareDestination {
        let icon = Image(uiImage: UIImage(systemName: "ellipsis",
                                          withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold))!.withRenderingMode(.alwaysTemplate))
        return ShareDestination(name: L10n.shareMoreActions, icon: icon, action: { option in
            let activityViewController = UIActivityViewController(activityItems: [option.shareURL], applicationActivities: nil)
            vc.presentedViewController?.present(activityViewController, animated: true, completion: nil)
        })
    }

    static var copyLinkOption: ShareDestination {
        return ShareDestination(name: L10n.shareCopyLink, icon: Image("pocketcasts"), action: { option in
            UIPasteboard.general.string = option.shareURL
            Toast.show(L10n.shareCopiedToClipboard)
        })
    }
}

extension SharingModal.Option {
    var description: String {
        switch self {
        case .episode(let episode), .currentPosition(let episode, _):
            if let date = episode.publishedDate {
                return date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted))
            } else {
                return ""
            }
        case .podcast(let podcast):
            return [podcast.episodeCount, podcast.frequency].compactMap { $0 }.joined(separator: " ⋅ ")
        }
    }

    var title: String? {
        switch self {
        case .episode(let episode), .currentPosition(let episode, _):
            episode.title
        case .podcast(let podcast):
            podcast.title
        }
    }

    var name: String? {
        switch self {
        case .episode(let episode), .currentPosition(let episode, _):
            episode.parentPodcast()?.title
        case .podcast(let podcast):
            podcast.author
        }
    }

    var podcast: Podcast {
        switch self {
        case .episode(let episode), .currentPosition(let episode, _):
            return episode.parentPodcast()!
        case .podcast(let podcast):
            return podcast
        }
    }

    var imageInfo: ShareImageInfo {
        let gradient = Gradient(colors: [
            Color(uiColor: ColorManager.lightThemeTintForPodcast(podcast)),
            Color(uiColor: UIColor.calculateColor(orgColor: UIColor.black, overlayColor: ColorManager.lightThemeTintForPodcast(podcast).withAlphaComponent(0.8))),
        ])
        let artwork = ImageManager.sharedManager.podcastUrl(imageSize: .page, uuid: podcast.uuid)
        let imageInfo = ShareImageInfo(name: name!,
                                       title: title!,
                                       description: description,
                                       artwork: artwork,
                                       gradient: gradient)
        return imageInfo
    }

    var shareURL: String {
        switch self {
        case .episode(let episode):
            return episode.shareURL
        case .podcast(let podcast):
            return podcast.shareURL
        case .currentPosition(let episode, let timeInterval):
            return episode.shareURL + "?t=\(round(timeInterval))"
        }
    }
}

extension Podcast {
    fileprivate var episodeCount: String? {
        let count = PodcastManager.episodeCountForPodcast(self, excludeArchive: false)
        guard count > 0 else {
            return nil
        }
        return L10n.episodeCountPluralFormat(count)
    }

    fileprivate var frequency: String? {
        guard let frequency = episodeFrequency?.lowercased(), frequency != "unknown" else {
            return nil
        }
        return L10n.paidPodcastReleaseFrequencyFormat(frequency)
    }
}

struct SharingView: View {

    private enum Constants {
        static let descriptionMaxWidth: CGFloat = 200
    }

    let destinations: [ShareDestination]
    let selectedOption: SharingModal.Option

    @State private var selectedMedia: ShareImageStyle = .large

    var body: some View {
        VStack {
            title
            image
            buttons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color.white)
    }

    @ViewBuilder var title: some View {
        VStack {
            Text(selectedOption.shareTitle)
                .font(.headline)
            Text(L10n.shareDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: Constants.descriptionMaxWidth)
        }
    }

    @ViewBuilder var image: some View {
        TabView(selection: $selectedMedia) {
            ForEach(ShareImageStyle.allCases, id: \.self) { style in
                ShareImageView(info: selectedOption.imageInfo, style: style)
                    .tabItem { Text(style.tabString) }
            }
        }
        .tabViewStyle(.page)
    }

    @ViewBuilder var buttons: some View {
        HStack(spacing: 24) {
            ForEach(destinations, id: \.self) { option in
                Button {
                    option.action(selectedOption)
                } label: {
                    VStack {
                        option.icon
                            .frame(width: 24, height: 24)
                            .padding(15)
                            .background {
                                Circle()
                                    .foregroundStyle(.white.opacity(0.1))
                            }
                        Text(option.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    SharingView(destinations: [.copyLinkOption], selectedOption: .podcast(Podcast.previewPodcast()))
}
