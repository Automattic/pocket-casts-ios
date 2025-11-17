import SwiftUI

protocol PlaylistPlayAllSheetHostDelegate: AnyObject {
    func onTapSaveAndReplace()
}

class PlaylistPlayAllSheetHost: ThemedHostingController<PlaylistPlayAllSheet> {
    typealias Delegate = PlaylistPlayAllSheetHostDelegate & UISheetPresentationControllerDelegate

    private weak var delegate: Delegate?

    init(delegate: Delegate?) {
        self.delegate = delegate

        let screen = PlaylistPlayAllSheet(
            delegate: delegate,
            isSelected: .init(
                get: { Settings.saveCurrentUpNextQueueIntoPlaylist },
                set: { Settings.saveCurrentUpNextQueueIntoPlaylist = $0 }
            )
        )
        super.init(rootView: screen)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupSheetController()
    }

    private func setupUI() {
        view.backgroundColor = ThemeColor.primaryUi01()
    }

    private func setupSheetController() {
        if let sheetController = sheetPresentationController {
            sheetController.detents = [.custom { _ in
                return 380.0
            }]
            sheetController.prefersGrabberVisible = true
            sheetController.delegate = delegate
        }
    }
}
