import UIKit

class ChaptersHeader: UIView {
    weak var delegate: ChaptersHeaderDelegate?

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
        let header = UIStackView()
        header.layoutMargins = .init(top: 0, left: 12, bottom: 0, right: 12)
        header.isLayoutMarginsRelativeArrangement = true
        header.axis = .horizontal
        header.backgroundColor = .black
        let label = UILabel()
        label.text = L10n.numberOfChapters(PlaybackManager.shared.chapterCount(onlyPlayable: true))
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .footnote)
        let button = UIButton()
        button.setTitle("Skip chapters", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.addTarget(self, action: #selector(toggleChapterSelection), for: .touchUpInside)
        header.addArrangedSubview(label)
        header.addArrangedSubview(button)
        addSubview(header)
        header.anchorToAllSidesOf(view: self)
    }

    @objc func toggleChapterSelection() {
        delegate?.toggleTapped()
    }
}

protocol ChaptersHeaderDelegate: AnyObject {
    func toggleTapped()
}
