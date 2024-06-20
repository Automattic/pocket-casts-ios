import SwiftUI

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
                Image("X")
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
        let icon = Image(systemName: "ellipsis")
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
