import UIKit
import PocketCastsDataModel

final class EpisodePreviewViewController: UIViewController {
    private let episode: BaseEpisode
    private let themeOverride: Theme.ThemeType?

    init(episode: BaseEpisode, themeOverride: Theme.ThemeType? = nil) {
        self.episode = episode
        self.themeOverride = themeOverride
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppTheme.colorForStyle(.primaryUi02, themeOverride: themeOverride)

        let imageSize: CGFloat = 80
        let imageView = PodcastImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        if let userEpisode = episode as? UserEpisode {
            imageView.setUserEpisode(uuid: userEpisode.uuid, size: .page)
        } else {
            imageView.setBaseEpisode(episode: episode, size: .page)
        }
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: imageSize),
            imageView.heightAnchor.constraint(equalToConstant: imageSize),
        ])

        let dateLabel = UILabel()
        dateLabel.font = .font(ofSize: 12, weight: .regular, scalingWith: .caption1)
        dateLabel.textColor = AppTheme.colorForStyle(.primaryText02, themeOverride: themeOverride)
        if let publishedDate = episode.publishedDate {
            dateLabel.text = publishedDate.formatted(date: .abbreviated, time: .omitted)
        } else {
            dateLabel.text = L10n.podcastNoDate
        }
        dateLabel.numberOfLines = 1

        let titleLabel = UILabel()
        titleLabel.font = .font(ofSize: 15, weight: .medium, scalingWith: .subheadline)
        titleLabel.textColor = AppTheme.colorForStyle(.primaryText01, themeOverride: themeOverride)
        titleLabel.text = episode.title
        titleLabel.numberOfLines = 3

        let detailLabel = UILabel()
        detailLabel.font = .font(ofSize: 13, weight: .regular, scalingWith: .footnote)
        detailLabel.textColor = AppTheme.colorForStyle(.primaryText02, themeOverride: themeOverride)
        detailLabel.text = episode.displayableInfo(includeSize: false)
        detailLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [dateLabel, titleLabel, detailLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4

        let mainStack = UIStackView(arrangedSubviews: [imageView, textStack])
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.axis = .horizontal
        mainStack.alignment = .top
        mainStack.spacing = 12

        view.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
        ])

        let preferredWidth = min(360, UIScreen.main.bounds.width - 40)
        preferredContentSize = view.systemLayoutSizeFitting(
            CGSize(width: preferredWidth, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }
}
