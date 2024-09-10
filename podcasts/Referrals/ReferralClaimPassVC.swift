import Foundation

class ReferralClaimPassVC: ThemedHostingController<ReferralClaimPassView> {

    private let viewModel: ReferralClaimPassModel

    init(viewModel: ReferralClaimPassModel) {
        self.viewModel = viewModel
        let screen = ReferralClaimPassView(viewModel: viewModel)
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
        view.backgroundColor = .clear
    }
}
