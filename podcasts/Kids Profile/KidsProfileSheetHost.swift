import Foundation
import SwiftUI

class KidsProfileSheetHost: ThemedHostingController<KidsProfileSheet> {
    private let viewModel: KidsProfileSheetViewModel

    init(viewModel: KidsProfileSheetViewModel) {
        self.viewModel = viewModel

        let screen = KidsProfileSheet(viewModel: viewModel)
        super.init(rootView: screen)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupSheetController()
        setupViewModel()
    }

    private func setupUI() {
        view.backgroundColor = .white
    }

    private func setupSheetController() {
        if let sheetController = sheetPresentationController {
            sheetController.detents = [.medium()]
            sheetController.prefersGrabberVisible = true
        }
    }

    private func setupViewModel() {
        viewModel.onDismissScreenTap = { [weak self] in
            self?.dismiss(animated: true)
        }

        viewModel.onSendFeedbackTap = { [weak self] in
            self?.expandViewController()
        }
    }

    private func expandViewController() {
        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.animateChanges {
                sheet.selectedDetentIdentifier = .large
            }
        }
    }
}
