import SwiftUI

struct ShareDestination: Hashable {
    let name: String
    let icon: Image
    let action: (SharingModal.Option, ShareImageStyle) -> Void

    static func ==(lhs: ShareDestination, rhs: ShareDestination) -> Bool {
        lhs.name == rhs.name && lhs.icon == rhs.icon
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func moreOption(vc: UIViewController) -> ShareDestination {
        let icon = Image(systemName: "ellipsis")
        return ShareDestination(name: L10n.shareMoreActions, icon: icon, action: { option, style in
            Task.detached {
                let image = await ShareImageView.shareImage(option, style: style)
                let activityViewController = await UIActivityViewController(activityItems: [option.shareURL, image], applicationActivities: nil)
                await vc.presentedViewController?.present(activityViewController, animated: true, completion: nil)
            }
        })
    }

    static var copyLinkOption: ShareDestination {
        return ShareDestination(name: L10n.shareCopyLink, icon: Image("pocketcasts"), action: { option, _ in
            UIPasteboard.general.string = option.shareURL
            Toast.show(L10n.shareCopiedToClipboard)
        })
    }
}

fileprivate extension ShareImageView {
    @MainActor
    static func shareImage(_ option: SharingModal.Option, style: ShareImageStyle) -> UIImage {
        let imageView = ShareImageView(info: option.imageInfo, style: style)
        let image: UIImage
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: imageView)
            renderer.scale = 2
            image = renderer.uiImage!
        } else {
            image = imageView.snapshot()
        }

        return image
    }
}
