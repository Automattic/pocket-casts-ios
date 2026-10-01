import UIKit

class DateHeadingView: UIView {
    private var titleLabel: UILabel?

    var title = "" {
        didSet {
            titleLabel?.text = title
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        setup()
    }

    private func setup() {
        let label: UILabel

        if LiquidGlass.isEnabled {
            label = UILabel()
        } else {
            let dividerHeight = 1 / traitCollection.displayScale
            let topDivider = ThemeDividerView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: dividerHeight))
            topDivider.translatesAutoresizingMaskIntoConstraints = false
            addSubview(topDivider)

            let dividerHeightConstraint = topDivider.heightAnchor.constraint(equalToConstant: dividerHeight)
            NSLayoutConstraint.activate([
                dividerHeightConstraint,
                topDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
                topDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
                topDivider.topAnchor.constraint(equalTo: topAnchor)
            ])
            registerForTraitChanges([UITraitDisplayScale.self]) { (view: DateHeadingView, _) in
                dividerHeightConstraint.constant = 1 / view.traitCollection.displayScale
            }

            label = ThemeableLabel()
        }

        label.textAlignment = .natural
        label.text = title
        label.font = UIFont.font(ofSize: 22, weight: UIFont.Weight.bold, scalingWith: .largeTitle)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        titleLabel = label

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.topAnchor.constraint(equalTo: topAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        setBgColorForTheme()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func themeDidChange() {
        setBgColorForTheme()
    }

    private func setBgColorForTheme() {
        backgroundColor = LiquidGlass.isEnabled ? .clear : ThemeColor.primaryUi02()
    }
}
