import PocketCastsDataModel
import SwiftUI
import PocketCastsUtils

enum SharingModal {

    /// Share options including which type of content will be shared
    enum Option {
        case episode(Episode)
        case podcast(Podcast)
        case currentPosition(Episode, TimeInterval)
        case clip(Episode, TimeInterval)
        case clipShare(Episode, ClipTime, ShareImageStyle, Progress)

        var buttonTitle: String {
            switch self {
            case .episode:
                L10n.episode
            case .currentPosition:
                L10n.shareCurrentPosition
            case .podcast:
                L10n.podcastSingular
            case .clip, .clipShare:
                L10n.clip
            }
        }

        var shareTitle: String {
            switch self {
            case .episode:
                L10n.shareEpisode
            case .currentPosition(_, let time):
                L10n.shareEpisodeAt(TimeFormatter.shared.playTimeFormat(time: time))
            case .podcast:
                L10n.sharePodcast
            case .clip:
                L10n.createClip
            case .clipShare:
                L10n.shareClip
            }
        }

        static func allCases(episode: Episode?, podcast: Podcast, currentTime: TimeInterval) -> [Option] {
            if let episode {
                [
                    .episode(episode),
                    .podcast(podcast),
                    .currentPosition(episode, currentTime),
                    .clip(episode, currentTime)
                ]
            } else {
                [
                    .podcast(podcast)
                ]
            }
        }
    }

    static func showModal(episode: Episode, in viewController: UIViewController) {
        guard let podcast = episode.parentPodcast() else {
            assertionFailure("Podcast should exist for episode")
            return
        }
        showModal(podcast: podcast, episode: episode, in: viewController)
    }

    static func showModal(podcast: Podcast, episode: Episode?, in viewController: UIViewController) {
        let colors = OptionsPickerRootController.Colors(title: UIColor.white.withAlphaComponent(0.5), background: PlayerColorHelper.playerBackgroundColor01())

        let optionPicker = OptionsPicker(title: L10n.share.uppercased(), themeOverride: .dark, colors: colors)

        let timeInterval: Double
        if PlaybackManager.shared.currentEpisode()?.uuid == episode?.uuid {
            timeInterval = PlaybackManager.shared.currentTime()
        } else {
            timeInterval = episode?.playedUpTo ?? 0
        }

        let actions: [OptionAction] = Option.allCases(episode: episode, podcast: podcast, currentTime: timeInterval).map { option in
                .init(label: option.buttonTitle, action: {
                show(option: option, in: viewController)
            })
        }
        optionPicker.addActions(actions)

        if let vc = (viewController as? EpisodeDetailViewController),
           let fileAction = vc.episodeFileAction(from: .zero) {
            optionPicker.addAction(action: fileAction)
        }

        optionPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }

    static func show(option: Option, in viewController: UIViewController) {
        let sharingDestinations: [ShareDestination] = ShareDestination.displayedApps + [.copyLinkOption, .moreOption(vc: viewController)]
        let sharingView = SharingView(destinations: sharingDestinations, selectedOption: option)
        let modalView = ModalView {
            sharingView
        } dismissAction: {
            viewController.dismiss(animated: true)
        }
        .background(Color(PlayerColorHelper.playerBackgroundColor01()))

        let hostingController = ThemedHostingController(rootView: modalView, theme: Theme(previewTheme: .contrastLight))
        viewController.present(hostingController, animated: true)

    }
}

extension SharingModal.Option {
    private var description: String {
        switch self {
        case .episode(let episode), .currentPosition(let episode, _), .clip(let episode, _), .clipShare(let episode, _, _, _):
            if let date = episode.publishedDate {
                return date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted))
            } else {
                return ""
            }
        case .podcast(let podcast):
            return [podcast.episodeCount, podcast.frequency].compactMap { $0 }.joined(separator: " ⋅ ")
        }
    }

    private var title: String? {
        switch self {
        case .episode(let episode), .currentPosition(let episode, _), .clip(let episode, _), .clipShare(let episode, _, _, _):
            episode.title
        case .podcast(let podcast):
            podcast.title
        }
    }

    private var name: String? {
        switch self {
        case .episode(let episode), .currentPosition(let episode, _), .clip(let episode, _), .clipShare(let episode, _, _, _):
            episode.parentPodcast()?.title
        case .podcast(let podcast):
            podcast.author
        }
    }

    private var podcast: Podcast {
        switch self {
        case .episode(let episode), .currentPosition(let episode, _), .clip(let episode, _), .clipShare(let episode, _, _, _):
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
        let imageInfo = ShareImageInfo(name: name ?? "",
                                       title: title ?? "",
                                       description: description,
                                       artwork: artwork,
                                       gradient: gradient)
        return imageInfo
    }

    func itemProvider(style: ShareImageStyle) -> NSItemProvider {
        switch self {
        case .clipShare(_, _, _, let progress):
            guard let fileURL = progress.fileURL else {
                return ShareImageView(info: imageInfo, style: style, angle: .constant(0)).itemProvider()
            }
            if #available(iOS 16.0, *) {
                return NSItemProvider(contentsOf: fileURL, contentType: UTType(filenameExtension: fileURL.pathExtension) ?? .mpeg4Movie)
            } else {
                return NSItemProvider(contentsOf: fileURL)!
            }
        default:
            return ShareImageView(info: imageInfo, style: style, angle: .constant(0)).itemProvider()
        }
    }

    var shareURL: String {
        switch self {
        case .episode(let episode):
            return episode.shareURL
        case .podcast(let podcast):
            return podcast.shareURL
        case .currentPosition(let episode, let timeInterval):
            return episode.shareURL + "?t=\(round(timeInterval))"
        case .clip(let episode, let timeInterval):
            return episode.shareURL + "?t=\(round(timeInterval))"
        case .clipShare(let episode, let clipTime, _, _):
            return episode.shareURL + "?t=\(clipTime.start),\(clipTime.end)"
        }
    }
}

fileprivate extension Podcast {
    var episodeCount: String? {
        let count = PodcastManager.episodeCountForPodcast(self, excludeArchive: false)
        guard count > 0 else {
            return nil
        }
        return L10n.episodeCountPluralFormat(count)
    }

    var frequency: String? {
        guard let frequency = episodeFrequency?.lowercased(), frequency != "unknown" else {
            return nil
        }
        return L10n.paidPodcastReleaseFrequencyFormat(frequency)
    }
}
