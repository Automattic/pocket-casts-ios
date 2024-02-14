import UIKit

class ChaptersHeader: UIView {
    weak var delegate: ChaptersHeaderDelegate?

    private lazy var container: UIStackView = {
        let container = UIStackView()
        container.layoutMargins = .init(top: 0, left: 12, bottom: 0, right: 12)
        container.isLayoutMarginsRelativeArrangement = true
        container.axis = .horizontal
        container.backgroundColor = .black
        return container
    }()

    private lazy var chaptersLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.numberOfChapters(PlaybackManager.shared.chapterCount(onlyPlayable: true))
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .footnote)
        return label
    }()

    private lazy var toggleButton: UIButton = {
        let button = UIButton()
        button.setTitle("Skip chapters", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.addTarget(self, action: #selector(toggleChapterSelection), for: .touchUpInside)
        return button
    }()

    // MARK: - Config
    override init(frame: CGRect) {
        super.init(frame: frame)

        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        configure()
    }

    private func configure() {
        container.addArrangedSubview(chaptersLabel)
        container.addArrangedSubview(toggleButton)
        addSubview(container)
        container.anchorToAllSidesOf(view: self)
    }

    @objc func toggleChapterSelection() {
        delegate?.toggleTapped()
    }
}

protocol ChaptersHeaderDelegate: AnyObject {
    func toggleTapped()
}
