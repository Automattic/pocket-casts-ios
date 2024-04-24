import PocketCastsDataModel
import SwiftUI

enum SharingModal {

    enum Option: CaseIterable {
        case episode
        case currentPosition
        case podcast

        var title: String {
            switch self {
            case .episode:
                L10n.episode
            case .currentPosition:
                L10n.shareCurrentPosition
            case .podcast:
                L10n.podcastSingular
            }
        }
    }

    static func showModal(podcast: Podcast, episode: Episode?, in viewController: UIViewController) {
        let optionPicker = OptionsPicker(title: L10n.playerShareHeader)

        let actions: [OptionAction] = Option.allCases.map { option in
                .init(label: option.title, icon: "chapter-link", action: {
                show(option: option, podcast: podcast, episode: episode, in: viewController)
            })
        }
        optionPicker.addActions(actions)

        optionPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }

    static func show(option: Option, podcast: Podcast, episode: Episode?, in viewController: UIViewController) {
        let artworkURL = ImageManager.sharedManager.podcastUrl(imageSize: .page, uuid: podcast.uuid)
        let shareInfo = ShareInfo(podcast: podcast, episode: episode, artworkURL: artworkURL, backgroundColor: Color(hex: podcast.primaryColor ?? ""))

        print("Show \(shareInfo)")
    }
}
