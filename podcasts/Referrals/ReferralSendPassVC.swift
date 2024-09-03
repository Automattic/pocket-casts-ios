import Foundation

class ReferralSendPassVC: ThemedHostingController<ReferralSendPassView> {

    private let viewModel: ReferralSendPassModel

    init() {
        self.viewModel = ReferralSendPassModel()
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
        self.navigationController?.navigationBar.isHidden = true
        self.tabBarController?.hidesBottomBarWhenPushed = true
        self.tabBarController?.tabBar.isHidden = true
        NavigationManager.sharedManager.miniPlayer?.hideMiniPlayer(false)
    }

    private func prepareToDismiss() {
        self.navigationController?.navigationBar.isHidden = false
        self.tabBarController?.hidesBottomBarWhenPushed = false
        self.tabBarController?.tabBar.isHidden = false
        NavigationManager.sharedManager.miniPlayer?.showMiniPlayer()
        self.navigationController?.popViewController(animated: true)
    }

    private func setupViewModel() {
        viewModel.onShareGuestPassTap = { [weak self] in
            self?.prepareToDismiss()
        }
    }
}
