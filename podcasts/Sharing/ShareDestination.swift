import SwiftUI

struct ShareDestination: Hashable {
    let name: String
    let icon: Image
    let action: ((SharingModal.Option, ShareImageStyle) -> Void)?

    static func ==(lhs: ShareDestination, rhs: ShareDestination) -> Bool {
        lhs.name == rhs.name && lhs.icon == rhs.icon
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func moreOption(vc: UIViewController) -> ShareDestination {
        let icon = Image(systemName: "ellipsis")

        if #available(iOS 16, *) {
            return ShareDestination(name: L10n.shareMoreActions, icon: icon, action: nil)
        } else {
            return ShareDestination(name: L10n.shareMoreActions, icon: icon, action: { option, style in
                Task.detached {
                    let activityItems = [option.shareURL, option.itemProvider(style: style)]
                    let activityViewController = await UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                    await vc.presentedViewController?.present(activityViewController, animated: true, completion: nil)
                }
            })
        }
    }

    static var copyLinkOption: ShareDestination {
        return ShareDestination(name: L10n.shareCopyLink, icon: Image("pocketcasts"), action: { option, _ in
            UIPasteboard.general.string = option.shareURL
            Toast.show(L10n.shareCopiedToClipboard)
        })
    }
}
