import UIKit
import PocketCastsServer

class ChaptersHeader: UIView {
    weak var delegate: ChaptersHeaderDelegate?

    var isTogglingChapters = false

    private lazy var container: UIStackView = {
        let container = UIStackView()
        container.layoutMargins = .init(top: 0, left: 12, bottom: 0, right: 12)
        container.isLayoutMarginsRelativeArrangement = true
        container.axis = .horizontal
        return container
    }()

    private lazy var chaptersLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .footnote)
        return label
    }()

    private lazy var toggleButton: UIButton = {
        let button = UIButton(configuration: .plain())
        button.setTitle(L10n.skipChapters, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(toggleChapterSelection), for: .touchUpInside)
        button.semanticContentAttribute = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .forceLeftToRight : .forceRightToLeft
        button.configuration?.imagePadding = 8
        button.configuration?.image = lockIcon
        button.configuration?.titleTextAttributesTransformer =
           UIConfigurationTextAttributesTransformer { incoming in
             var outgoing = incoming
             outgoing.font = .preferredFont(forTextStyle: .footnote)
             return outgoing
         }
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()

    private lazy var divider: UIView = {
        let divider = UIView()
        divider.backgroundColor = .white.withAlphaComponent(0.15)
        divider.translatesAutoresizingMaskIntoConstraints = false
        return divider
    }()

    private var lockIcon: UIImage? {
        PaidFeature.deselectChapters.isUnlocked ? nil : (PaidFeature.deselectChapters.tier == .patron ? UIImage(named: "patron-heart") : UIImage(named: "plusGold"))
    }

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
        updateButtonLabel()
        updateButtonIcon()
    }

    private func configure() {
        container.addArrangedSubview(chaptersLabel)
        container.addArrangedSubview(toggleButton)
        addSubview(container)
        container.anchorToAllSidesOf(view: self)
        container.addSubview(divider)
        setUpConstraints()
    }

    @objc private func toggleChapterSelection() {
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
        let buttonTitle = isTogglingChapters ? L10n.done : L10n.skipChapters
        toggleButton.setTitle(buttonTitle, for: .normal)
    }

    private func updateButtonIcon() {
        toggleButton.configuration?.image = lockIcon
    }

    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
}

protocol ChaptersHeaderDelegate: AnyObject {
    func toggleTapped()
}
