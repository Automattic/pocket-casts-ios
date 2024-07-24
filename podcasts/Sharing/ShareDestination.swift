import SwiftUI

struct ShareDestination: Hashable {
    let name: String
    let icon: Image
    let action: (SharingModal.Option, ShareImageStyle) -> Void

    enum Constants {
        static let displayedAppsCount = 3
    }

    enum Media {
        case media
        case link
    }

    static func ==(lhs: ShareDestination, rhs: ShareDestination) -> Bool {
        lhs.name == rhs.name && lhs.icon == rhs.icon
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    enum Destination: CaseIterable {
        case instagram

        var name: String {
            switch self {
            case .instagram:
                "Stories"
            }
        }

        var icon: Image {
            switch self {
            case .instagram:
                Image("instagram")
            }
        }

        enum ShareError: Error {
            case noMatchingItemIdentifier
            case loadFailed(Error?)
        }

        func share(_ option: SharingModal.Option, style: ShareImageStyle) async throws {
            let item: (Data, UTType)? = await option.shareData(style: style, destination: self).mapFirst { shareItem in
                if let data = shareItem as? Data {
                    return (data, style == .audio ? .m4a : .mpeg4Movie)
                } else if let image = shareItem as? UIImage, let data = image.pngData() {
                    return (data, .png)
                } else {
                    return nil
                }
            }

            guard let item else {
                throw ShareError.noMatchingItemIdentifier
            }

            switch self {
            case .instagram:
                await instagramShare(data: item.0, type: item.1, url: option.shareURL)
            }
        }

        @MainActor
        static fileprivate func shareImage(_ option: SharingModal.Option, style: ShareImageStyle) -> UIImage {
            let imageView = ShareImageView(info: option.imageInfo, style: style, angle: .constant(0))
            return imageView.snapshot()
        }

        @MainActor
        private func instagramShare(data: Data, type: UTType, url: String) {
            let attributionURL = url
            let appID = ApiCredentials.instagramAppID

            guard let urlScheme = URL(string: "instagram-stories://share?source_application=\(appID)"),
                UIApplication.shared.canOpenURL(urlScheme) else {
                return
            }

            let dataKey = type == .mpeg4Movie ? "com.instagram.sharedSticker.backgroundVideo" : "com.instagram.sharedSticker.backgroundImage"
            let pasteboardItems = [[dataKey: data,
                                    "com.instagram.sharedSticker.contentURL": attributionURL]]
            let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [.expirationDate: Date().addingTimeInterval(5.minutes)]

            UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)

            UIApplication.shared.open(urlScheme)
        }

        var isIncluded: Bool {
            switch self {
            case .instagram:
                if let url = URL(string: "instagram-stories://share"), UIApplication.shared.canOpenURL(url) {
                    return true
                } else {
                    return false
                }
            default:
                return true
            }
        }
    }

    static var displayedApps: Array<ShareDestination>.SubSequence {
        apps.prefix(Constants.displayedAppsCount)
    }

    private static var apps: [ShareDestination] {
        return Destination.allCases.compactMap({ destination in
            guard destination.isIncluded else { return nil }
            return ShareDestination(name: destination.name, icon: destination.icon, action: { option, style in
                Task.detached {
                    try await destination.share(option, style: style)
                }
            })
        })
    }

    static func moreOption(vc: UIViewController) -> ShareDestination {
        let icon = Image(systemName: "ellipsis")

        return ShareDestination(name: L10n.shareMoreActions, icon: icon, action: { option, style in
            Task.detached {
                let data = await option.shareData(style: style)
                let activityViewController = await UIActivityViewController(activityItems: data, applicationActivities: nil)
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
