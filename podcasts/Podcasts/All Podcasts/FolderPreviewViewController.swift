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

        let folderColor = AppTheme.folderColor(colorInt: folder.color)
        let backdrop = UIView()
        backdrop.backgroundColor = folderColor
        backdrop.layer.cornerRadius = 8
        backdrop.layer.masksToBounds = true
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)

        let label = UILabel()
        label.text = folder.name
        label.textColor = ThemeColor.filterText01(filterColor: folderColor)
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        backdrop.addSubview(label)

        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.centerXAnchor.constraint(equalTo: backdrop.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: backdrop.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: backdrop.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: backdrop.trailingAnchor, constant: -16)
        ])
    }
}
