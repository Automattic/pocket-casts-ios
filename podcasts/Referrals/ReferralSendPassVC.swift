import Foundation

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
        setupViewModel()
    }

    private func setupUI() {
        view.backgroundColor = .clear
    }

    private func prepareToDismiss() {
        self.dismiss(animated: true)
    }

    private func setupViewModel() {
        viewModel.onCloseTap = { [weak self] in
            self?.prepareToDismiss()
        }
    }
}
