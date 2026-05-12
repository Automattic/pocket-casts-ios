import PocketCastsDataModel
import PocketCastsUtils
import UIKit

final class FolderPreviewViewController: UIViewController {
    private let folder: Folder

    init(folder: Folder) {
        self.folder = folder
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = CGSize(width: 280, height: 280)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true

        let folderPreview = FolderPreviewView()
        view.addSubview(folderPreview)
        folderPreview.pinEdges()

        folderPreview.populateFromAsync(folder: folder)
    }
}
