import Foundation
import LinkPresentation

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

        setupUI()
    }

    private func setupUI() {
        let originalDismiss = viewModel.onShareGuestPassTap
        viewModel.onShareGuestPassTap = { [weak self] in
            guard let self else { return }
            let viewController = UIActivityViewController(activityItems: [viewModel, viewModel.shareURL], applicationActivities: nil)
            viewController.completionWithItemsHandler = { _, completed, _, _ in
                if completed {
                    originalDismiss?()
                }
            }
            present(viewController, animated: true)
        }
        view.backgroundColor = .clear
    }
}

extension ReferralSendPassModel: UIActivityItemSource {
    var shareURL: URL { URL(string: //"https://pocketcasts.com/redeem-guest-pass")!
        "https://pocketcasts.com")!
    }

    var text: String {
        "Hey! Use the link below to claim your 2-month guest pass for Pocket Casts Plus and enjoy podcasts across all your devices!\n\n\(shareURL.absoluteString)"
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return text
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if let activityType {
            
        }
        return text
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "2-month Guest Pass for Pocket Casts Plus!"
    }

    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.originalURL = shareURL
        metadata.url = metadata.originalURL
        metadata.title = text
        return metadata
    }

//    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
//        return UIImage(named: "AppIcon-Default")
//    }
}
