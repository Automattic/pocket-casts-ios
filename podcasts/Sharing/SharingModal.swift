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
        let colors = OptionsPickerRootController.Colors(title: UIColor.white.withAlphaComponent(0.5), background: PlayerColorHelper.playerBackgroundColor01())

        let optionPicker = OptionsPicker(title: L10n.share.uppercased(), themeOverride: .dark, colors: colors)

        let actions: [OptionAction] = Option.allCases.map { option in
                .init(label: option.title, action: {
                show(option: option, podcast: podcast, episode: episode, in: viewController)
            })
        }
        optionPicker.addActions(actions)

        optionPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }

    static func show(option: Option, podcast: Podcast, episode: Episode?, in viewController: UIViewController) {
        let shareInfo = ShareInfo(podcast: podcast, episode: episode)

        let sharingView = SharingView(shareInfo: shareInfo)
        let modalView = ModalView(view: {
            AnyView(sharingView)
        }, dismissAction: {
            viewController.dismiss(animated: true)
        })
        .background(Color(PlayerColorHelper.playerBackgroundColor01()))

        let hostingController = ThemedHostingController(rootView: modalView, theme: Theme(previewTheme: .contrastLight))
        viewController.present(hostingController, animated: true)

    }
}
