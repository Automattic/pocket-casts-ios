import PocketCastsDataModel
import SwiftUI
import PocketCastsUtils

enum SharingModal {

    /// Share options including which type of content will be shared
    enum Option {
        case episode(Episode)
        case currentPosition(Episode, TimeInterval)
        case podcast(Podcast)

        var buttonTitle: String {
            switch self {
            case .episode:
                L10n.episode
            case .currentPosition:
                L10n.shareCurrentPosition
            case .podcast:
                L10n.podcastSingular
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
            }
        }

        static func allCases(episode: Episode?, podcast: Podcast, currentTime: TimeInterval) -> [Option] {
            if let episode {
                [
                    .episode(episode),
                    .podcast(podcast),
                    .currentPosition(episode, currentTime)
                ]
            } else {
                [
                    .podcast(podcast)
                ]
            }
        }
    }

    static func showModal(episode: Episode, in viewController: UIViewController) {
        guard let podcast = DataManager.sharedManager.findPodcast(uuid: episode.podcastUuid) else {
            assertionFailure("Podcast should exist for episode")
            return
        }
        showModal(podcast: podcast, episode: episode, in: viewController)
    }

    static func showModal(podcast: Podcast, episode: Episode?, in viewController: UIViewController) {
        let colors = OptionsPickerRootController.Colors(title: UIColor.white.withAlphaComponent(0.5), background: PlayerColorHelper.playerBackgroundColor01())

        let optionPicker = OptionsPicker(title: L10n.share.uppercased(), themeOverride: .dark, colors: colors)

        let actions: [OptionAction] = Option.allCases(episode: episode, podcast: podcast, currentTime: PlaybackManager.shared.currentTime()).map { option in
                .init(label: option.buttonTitle, action: {
                show(option: option, podcast: podcast, episode: episode, in: viewController)
            })
        }
        optionPicker.addActions(actions)

        optionPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }

    static func show(option: Option, episode: Episode, in viewController: UIViewController) {
        guard let podcast = DataManager.sharedManager.findPodcast(uuid: episode.podcastUuid) else {
            assertionFailure("Podcast should exist for episode")
            return
        }
        show(option: option, podcast: podcast, episode: episode, in: viewController)
    }

    static func show(option: Option, podcast: Podcast, episode: Episode?, in viewController: UIViewController) {
        let shareDestinations = Array(ShareDestination.apps[0...1]) + [.copyLinkOption, .moreOption(vc: viewController)]
        let sharingView = SharingView(destinations: shareDestinations, selectedOption: option)
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
