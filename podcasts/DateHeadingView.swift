
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

        titleLabel = ThemeableLabel(frame: CGRect(x: 20, y: 10, width: bounds.width - 20, height: 30))
        titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.bold)
        titleLabel?.textAlignment = .natural
        titleLabel?.text = title
        titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel!)

        // setup constraints so that they are all in the right place
        NSLayoutConstraint.activate([
            topDivider.heightAnchor.constraint(equalToConstant: dividerHeight),
            topDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            topDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            topDivider.topAnchor.constraint(equalTo: topAnchor),

            titleLabel!.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            bottomAnchor.constraint(equalTo: titleLabel!.bottomAnchor, constant: 10)
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
