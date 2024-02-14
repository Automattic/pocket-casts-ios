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
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .footnote)
        return label
    }()

    private lazy var toggleButton: UIButton = {
        let button = UIButton()
        button.setTitle(L10n.skipChapters, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.addTarget(self, action: #selector(toggleChapterSelection), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()

    // MARK: - Config
    override init(frame: CGRect) {
        super.init(frame: frame)

        configure()
        updateChapterLabel()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        configure()
    }

    func update() {
        updateChapterLabel()
    }

    private func configure() {
        container.addArrangedSubview(chaptersLabel)
        container.addArrangedSubview(toggleButton)
        addSubview(container)
        container.anchorToAllSidesOf(view: self)
    }

    @objc private func toggleChapterSelection() {
        updateButtonLabel()
        delegate?.toggleTapped()
    }

    private func updateChapterLabel() {
        let chapterCount = PlaybackManager.shared.chapterCount(onlyPlayable: true)
        let hiddenChapterCount = PlaybackManager.shared.chapterCount(onlyPlayable: false) - chapterCount
        var label = chapterCount > 1 ? L10n.numberOfChapters(chapterCount) : L10n.singleChapter
        if hiddenChapterCount > 0 {
            label += " • \(L10n.numberOfHiddenChapters(hiddenChapterCount))"
        }
        chaptersLabel.text = label
    }

    private func updateButtonLabel() {
        let buttonTitle = toggleButton.title(for: .normal) == L10n.skipChapters ? L10n.done : L10n.skipChapters
        toggleButton.setTitle(buttonTitle, for: .normal)
    }
}

protocol ChaptersHeaderDelegate: AnyObject {
    func toggleTapped()
}
