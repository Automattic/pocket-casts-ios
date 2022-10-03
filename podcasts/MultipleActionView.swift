import UIKit

class MultipleActionView: UIView {
    private let name: String
    private let icon: String?
    private let actions: [OptionAction]
    private let themeOverride: Theme.ThemeType?

    private let iconActionWidth: CGFloat = 45
    private let componentHeight: CGFloat = 44

    init(frame: CGRect, name: String, icon: String?, actions: [OptionAction], themeOverride: Theme.ThemeType? = nil) {
        self.name = name
        self.icon = icon
        self.actions = actions
        self.themeOverride = themeOverride

        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func actionWasAdded() {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.text = name
        label.textColor = AppTheme.mainTextColor(for: themeOverride)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        if let icon = icon, let image = UIImage(named: icon)?.tintedImage(ThemeColor.primaryIcon01(for: themeOverride)) {
            let imageView = UIImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 24),
                imageView.widthAnchor.constraint(equalToConstant: 24),
                label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 20),
                label.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                label.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }

        let segmentedControl = CustomSegmentedControl()
        var segmentedActions = [SegmentedAction]()
        for (index, action) in actions.enumerated() {
            guard let icon = action.icon, let image = UIImage(named: icon) else { continue }

            if action.selected { segmentedControl.selectedIndex = index }
            segmentedActions.append(SegmentedAction(icon: image, accessibilityLabel: action.label))
        }
        segmentedControl.setActions(segmentedActions)
        segmentedControl.lineColor = ThemeColor.primaryInteractive01(for: themeOverride)
        segmentedControl.unselectedItemColor = ThemeColor.primaryInteractive01(for: themeOverride)
        segmentedControl.selectedBgColor = ThemeColor.primaryInteractive01(for: themeOverride)
        segmentedControl.selectedItemColor = ThemeColor.primaryInteractive02(for: themeOverride)
        segmentedControl.unselectedBgColor = UIColor.clear
        addSubview(segmentedControl)

        NSLayoutConstraint.activate([
            trailingAnchor.constraint(equalTo: segmentedControl.trailingAnchor, constant: 20),
            segmentedControl.widthAnchor.constraint(equalToConstant: (CGFloat(actions.count) * iconActionWidth) + (CGFloat(actions.count - 1) * CustomSegmentedControl.separatorWidth)),
            segmentedControl.heightAnchor.constraint(equalToConstant: componentHeight),
            segmentedControl.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        segmentedControl.addTarget(self, action: #selector(optionSelected), for: .valueChanged)
    }

    @objc private func optionSelected(_ sender: CustomSegmentedControl) {
        if let action = actions[safe: sender.selectedIndex] {
            action.action()
        }
    }
}
