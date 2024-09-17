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

    private weak var popoverVC: UIPopoverPresentationController?

    private func setupUI() {
        let originalOnShareGuestPassTap = viewModel.onShareGuestPassTap
        viewModel.onShareGuestPassTap = { [weak self] in
            guard let self else { return }
            var items: [Any] = [TextAndURLShareSource.makeFrom(viewModel: viewModel)]
            if let url = viewModel.referralURL {
                items.append(url)
            }
            let viewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
            viewController.completionWithItemsHandler = { _, completed, _, _ in
                if completed {
                    originalOnShareGuestPassTap?()
                }
            }
            if let popoverVC  = viewController.popoverPresentationController {
                self.popoverVC = popoverVC
                popoverVC.sourceView = self.view
                popoverVC.sourceRect = centerBottomSourceRect
            }
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
        return "\(text)\n\n\(url?.absoluteString ?? "")"
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return subject
    }
}

extension TextAndURLShareSource {

    static func makeFrom(viewModel: ReferralSendPassModel) -> TextAndURLShareSource {
        return TextAndURLShareSource(url: viewModel.referralURL, text: viewModel.shareText, subject: viewModel.shareSubject)
    }
}
