import Foundation
import LinkPresentation
import SwiftUI
import PocketCastsServer

class ReferralSendPassVC: ThemedHostingController<ReferralSendPassView> {

    private let viewModel: ReferralSendPassModel

    init(viewModel: ReferralSendPassModel) {
        self.viewModel = viewModel
        let screen = ReferralSendPassView(viewModel: viewModel)
        super.init(rootView: screen)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Analytics.track(.referralShareScreenShown)

        setupUI()
    }

    private weak var popoverVC: UIPopoverPresentationController?

    private func setupUI() {
        let originalOnShareGuestPassTap = viewModel.onShareGuestPassTap
        viewModel.onShareGuestPassTap = { [weak self] in
            guard let self else { return }

            Analytics.track(.referralPassShared)

            var items: [Any] = [TextAndURLShareSource.makeFrom(viewModel: viewModel)]
            if let url = viewModel.referralURL {
                items.append(url)
            }
            if let imageSource = ImageShareSource(image: snapshot(), title: viewModel.shareSubject) {
                items.append(imageSource)
            }
            let viewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
            viewController.completionWithItemsHandler = { _, completed, _, _ in
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
                if completed {
                    originalOnShareGuestPassTap?()
                }
            }
            if let popoverVC  = viewController.popoverPresentationController {
                self.popoverVC = popoverVC
                popoverVC.sourceView = self.view
                popoverVC.sourceRect = centerBottomSourceRect
            }
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
            present(viewController, animated: true)
        }
        view.backgroundColor = .clear
    }

    private var centerBottomSourceRect: CGRect {
        CGRect(x: self.view.bounds.width / 2, y: self.view.bounds.height - 25, width: 5, height: 5)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        popoverVC?.sourceRect = centerBottomSourceRect
    }

    func snapshot() -> UIImage {
        return ReferralCardView(offerDuration: viewModel.offerInfo.localizedOfferDurationAdjective)
            .frame(width: ReferralCardView.Constants.defaultCardSize.width, height: ReferralCardView.Constants.defaultCardSize.height)
            .snapshot(scale: 2)
    }
}

class TextAndURLShareSource: NSObject, UIActivityItemSource {

    let url: URL?
    let text: String
    let subject: String

    init(url: URL?, text: String, subject: String) {
        self.url = url
        self.text = text
        self.subject = subject
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return "\(text)\n\n\(url?.absoluteString ?? "")"
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return text
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return subject
    }
}

extension TextAndURLShareSource {

    @MainActor
    static func makeFrom(viewModel: ReferralSendPassModel) -> TextAndURLShareSource {
        return TextAndURLShareSource(url: viewModel.referralURL, text: viewModel.shareText, subject: viewModel.shareSubject)
    }
}

class ImageShareSource: NSObject, UIActivityItemSource {
    private let image: UIImage
    private let url: URL?
    private let title: String

    init?(image: UIImage, title: String) {
        self.title = title
        self.image = image
        if let data = image.pngData(),
           let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(UUID().uuidString + ".png") {
            do {
                try data.write(to: url)
                self.url = url
            }
            catch {
                self.url = nil
            }
        } else {
            self.url = nil
        }
    }

    func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
        return image
    }

    func activityViewController(_: UIActivityViewController, itemForActivityType type: UIActivity.ActivityType?) -> Any? {
        // Instagram and twitter don't like to have an URL and image at the same time, so we are ignoring the image for those.
        if type?.rawValue == "com.burbn.instagram.shareextension" || type == .postToTwitter {
            return nil
        }
        return url
    }

    func activityViewController(_: UIActivityViewController, dataTypeIdentifierForActivityType _: UIActivity.ActivityType?) -> String {
        return UTType.image.identifier
    }

    func activityViewController(_: UIActivityViewController, thumbnailImageForActivityType _: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        image.resized(to: size)
    }

    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()

        metadata.originalURL = URL(string: ServerConstants.Urls.pocketcastsDotCom)
        metadata.url = URL(string: ServerConstants.Urls.pocketcastsDotCom)
        metadata.title = title
        metadata.imageProvider = NSItemProvider.init(contentsOf: url)

        return metadata
    }
}
