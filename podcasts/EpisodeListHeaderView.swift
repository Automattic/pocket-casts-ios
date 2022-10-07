import Combine
import PocketCastsServer
import UIKit

class EpisodeListHeaderView: UIView {
    private var cancellables = Set<AnyCancellable>()
    @Published var contentViewSize: CGSize = .zero

    @IBOutlet var contentView: ThemeableView! {
        didSet {
            contentView.style = .primaryUi02
        }
    }

    @IBOutlet var headerImageView: UIImageView!
    @IBOutlet var subtitle: UILabel!
    @IBOutlet var listTitle: ThemeableLabel!
    @IBOutlet var listDescription: ThemeableLabel! {
        didSet {
            listDescription.style = .primaryText02
        }
    }

    weak var linkDelegate: CollectionHeaderLinkDelegate?
    @IBOutlet var linkView: ThemeableView! {
        didSet {
            linkView.style = .primaryUi06
            linkView.layer.cornerRadius = 8

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(linkTapped))
            linkView.addGestureRecognizer(tapGesture)
        }
    }

    @IBOutlet var linkLabel: ThemeableLabel! {
        didSet {
            linkLabel.style = .primaryText02
        }
    }

    @IBOutlet var linkImageView: ThemeableImageView! {
        didSet {
            linkImageView.imageStyle = .primaryIcon02
        }
    }

    @IBOutlet var linkArrowImageView: ThemeableImageView! {
        didSet {
            linkArrowImageView.imageStyle = .primaryIcon02
        }
    }

    let podcastCollection: PodcastCollection
    init(collection: PodcastCollection) {
        podcastCollection = collection
        super.init(frame: .zero)

        Bundle.main.loadNibNamed(String(describing: EpisodeListHeaderView.self), owner: self, options: nil)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.widthAnchor.constraint(equalTo: widthAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor)
        ])

        subtitle.text = podcastCollection.subtitle?.localizedUppercase
        listTitle.text = podcastCollection.title
        listDescription.text = podcastCollection.description

        if let linkTitle = collection.webTitle, collection.webUrl != nil {
            linkView.isHidden = false
            linkLabel.text = linkTitle
        } else {
            linkView.isHidden = true
        }

        if let headerImage = podcastCollection.headerImage {
            ImageManager.sharedManager.loadDiscoverImage(imageUrl: headerImage, imageView: headerImageView)
        }

        Theme.sharedTheme.$activeTheme
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] _ in
                self.updateTheme()
            })
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentViewSize = contentView.frame.size
        updateTheme()
    }

    func updateTheme() {
        subtitle.textColor = podcastCollection.colors?.activeThemeColor ?? AppTheme.colorForStyle(.support02)
    }

    @objc private func linkTapped() {
        linkDelegate?.linkTapped()
    }
}
