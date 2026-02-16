import UIKit
import PocketCastsServer

class ChaptersHeader: UIView {
    weak var delegate: ChaptersHeaderDelegate?

    var isTogglingChapters = false

    private lazy var container: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()

    private lazy var chaptersLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .font(ofSize: 12, scalingWith: .footnote)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var toggleButton: UIButton = {
        let button = UIButton(configuration: .plain())
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(L10n.skipChapters, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(toggleChapterSelection), for: .touchUpInside)
        button.semanticContentAttribute = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .forceLeftToRight : .forceRightToLeft
        button.configuration?.imagePadding = 8
        button.configuration?.image = lockIcon
        button.configuration?.titleTextAttributesTransformer =
           UIConfigurationTextAttributesTransformer { incoming in
             var outgoing = incoming
             outgoing.font = .font(ofSize: 12, scalingWith: .footnote)
             return outgoing
         }
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
        container.addSubview(chaptersLabel)
        container.addSubview(toggleButton)
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
            divider.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2.0),

            chaptersLabel.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor),
            chaptersLabel.topAnchor.constraint(equalTo: container.topAnchor),
            chaptersLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            chaptersLabel.trailingAnchor.constraint(equalTo: toggleButton.leadingAnchor),
            chaptersLabel.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.40),

            toggleButton.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor),
            toggleButton.topAnchor.constraint(equalTo: container.layoutMarginsGuide.topAnchor),
            toggleButton.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor),
            toggleButton.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.5),

            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        chaptersLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        toggleButton.setContentHuggingPriority(.defaultLow, for: .vertical)

        chaptersLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        toggleButton.setContentCompressionResistancePriority(.required, for: .vertical)
    }

}

protocol ChaptersHeaderDelegate: AnyObject {
    func toggleTapped()
}
