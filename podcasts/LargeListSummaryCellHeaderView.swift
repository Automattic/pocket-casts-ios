import PocketCastsDataModel

class LargeListSummaryCellHeaderView: UIView {
    private let horizontalStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()

    private let imageView: PodcastImageView = {
        let imageView = PodcastImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let verticalStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        return stack
    }()

    private let topLabel: ThemeableLabel = {
        let label = ThemeableLabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = ThemeColor.primaryText02()
        return label
    }()

    private let bottomLabel: ThemeableLabel = {
        let label = ThemeableLabel()
        label.textColor = ThemeColor.primaryText01()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.numberOfLines = 0
        return label
    }()

    var topText: String? {
        get { topLabel.text }
        set { topLabel.text = newValue }
    }

    var bottomText: String? {
        get { bottomLabel.text }
        set { bottomLabel.text = newValue }
    }

    var podcastUUID: String? {
        didSet {
            toggleExtras(hidden: podcastUUID == nil)
            if let uuid = podcastUUID {
                imageView.setPodcast(uuid: uuid, size: .list)
                if let podcast = DataManager.sharedManager.findPodcast(uuid: uuid) {
                    bottomLabel.text = podcast.title
                }
            }
        }
    }

    func toggleExtras(hidden: Bool) {
        topLabel.isHidden = hidden
        imageView.isHidden = hidden
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(horizontalStack)
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            horizontalStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalStack.topAnchor.constraint(equalTo: topAnchor),
            horizontalStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 44),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])

        verticalStack.addArrangedSubview(topLabel)
        verticalStack.addArrangedSubview(bottomLabel)

        horizontalStack.addArrangedSubview(imageView)
        horizontalStack.addArrangedSubview(verticalStack)
    }
}
