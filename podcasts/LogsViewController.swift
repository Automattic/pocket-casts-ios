import Foundation

class LogsViewController: ThemedHostingController<LogsView> {
    private let source: OnlineSupportController.Source

    init(source: OnlineSupportController.Source) {
        self.source = source

        let model = LogsViewModel()
        let screen = LogsView(model: model)
        super.init(rootView: screen)
        model.presenter = self
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switch source {
        case .winback:
            Analytics.track(.winbackScreenShown, properties: ["screen": "logs"])
        default:
            break
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        switch source {
        case .winback:
            Analytics.track(.winbackScreenDismissed, properties: ["screen": "logs"])
        default:
            break
        }
    }

    private func setupUI() {
        view.backgroundColor = .clear
    }
}
