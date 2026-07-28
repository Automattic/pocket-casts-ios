import PocketCastsDataModel
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
        folderPreview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(folderPreview)
        NSLayoutConstraint.activate([
            folderPreview.topAnchor.constraint(equalTo: view.topAnchor),
            folderPreview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            folderPreview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            folderPreview.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        folderPreview.populateFromAsync(folder: folder)
    }
}
