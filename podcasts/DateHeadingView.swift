
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
        // add the label and dividers
        let dividerHeight = 1 / UIScreen.main.scale
        let topDivider = ThemeDividerView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: dividerHeight))
        topDivider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topDivider)

        titleLabel = ThemeableLabel()
        titleLabel?.textAlignment = .natural
        titleLabel?.text = title
        titleLabel?.font = UIFont.font(ofSize: 22, weight: UIFont.Weight.bold, scalingWith: .largeTitle)
        titleLabel?.adjustsFontForContentSizeCategory = true
        addSubview(titleLabel!)
        titleLabel?.translatesAutoresizingMaskIntoConstraints = false

        // setup constraints so that they are all in the right place
        NSLayoutConstraint.activate([
            topDivider.heightAnchor.constraint(equalToConstant: dividerHeight),
            topDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            topDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            topDivider.topAnchor.constraint(equalTo: topAnchor),

            titleLabel!.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel!.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            titleLabel!.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            titleLabel!.topAnchor.constraint(equalTo: topAnchor, constant: 0)
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
        backgroundColor = ThemeColor.primaryUi02()
    }
}
