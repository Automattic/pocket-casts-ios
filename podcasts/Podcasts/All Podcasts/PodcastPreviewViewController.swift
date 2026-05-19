import UIKit

final class PodcastPreviewViewController: UIViewController {
    private let podcastUUID: String

    init(podcastUUID: String) {
        self.podcastUUID = podcastUUID
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

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        ImageManager.sharedManager.loadImage(podcastUuid: podcastUUID, imageView: imageView, size: .page, showPlaceHolder: true)
    }
}
