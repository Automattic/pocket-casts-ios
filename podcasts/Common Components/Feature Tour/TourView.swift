import UIKit

class TourView: ThemeableView {
    var step: TourStep? {
        didSet {
            updateForStep()
        }
    }

    var position = 0
    var totalStepCount: Int

    weak var delegate: TourDelegate?

    private var leftLabel: ThemeableLabel!
    private var closeBtn: ThemeableUIButton!
    private var headingLabel: ThemeableLabel!
    private var descriptionLabel: ThemeableLabel!
    private var button: ThemeableRoundedButton!

    init(stepCount: Int) {
        totalStepCount = stepCount
        super.init(frame: CGRect.zero)

        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        layer.cornerRadius = 20
        clipsToBounds = true

        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.spacing = 12
        verticalStack.distribution = .equalSpacing
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(verticalStack)
        verticalStack.anchorToAllSidesOf(view: self, padding: 20)

        // top section
        let topStack = UIStackView()
        topStack.axis = .horizontal

        leftLabel = ThemeableLabel()
        leftLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        topStack.addArrangedSubview(leftLabel)

        closeBtn = ThemeableUIButton()
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeBtn.style = .primaryInteractive01
        closeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        topStack.addArrangedSubview(closeBtn)

        verticalStack.addArrangedSubview(topStack)

        // heading
        headingLabel = ThemeableLabel()
        headingLabel.numberOfLines = 0
        headingLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        verticalStack.addArrangedSubview(headingLabel)

        // description
        descriptionLabel = ThemeableLabel()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.style = .primaryText02
        descriptionLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        verticalStack.addArrangedSubview(descriptionLabel)

        // padding(ton bear)

        let paddingView = UIView()
        paddingView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        verticalStack.addArrangedSubview(paddingView)

        // big button

        button = ThemeableRoundedButton()
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        verticalStack.addArrangedSubview(button)
    }

    private func updateForStep() {
        leftLabel.style = position == 0 ? .support05 : .primaryText02
        leftLabel.text = position == 0 ? L10n.featureTourNew : L10n.featureTourStepFormat(position.localized(), (totalStepCount - 1).localized())

        if position == 0 {
            closeBtn.setTitle(L10n.close, for: .normal)
        } else {
            closeBtn.setTitle(L10n.featureTourEndTour, for: .normal)
        }

        headingLabel.text = step?.title
        descriptionLabel.text = step?.detail
        button.setTitle(step?.buttonTitle, for: .normal)
    }

    @objc func closeTapped() {
        delegate?.endTourTapped()
    }

    @objc func buttonTapped() {
        delegate?.nextTapped()
    }
}
