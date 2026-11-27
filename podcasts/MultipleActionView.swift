import UIKit

class MultipleActionView: UIView {
    private let name: String
    private let icon: String?
    private let actions: [OptionAction]
    private let themeOverride: Theme.ThemeType?
    private var imageView: UIImageView?
    private var label: UILabel?
    private var inlineConstraints: [NSLayoutConstraint] = []
    private var stackedConstraints: [NSLayoutConstraint] = []
    private var isStacked: Bool?
    private let iconActionWidth: CGFloat = 45
    private let componentHeight: CGFloat = 44

    private var segmentedControlWidth: CGFloat {
        (CGFloat(actions.count) * iconActionWidth) + (CGFloat(actions.count - 1) * CustomSegmentedControl.separatorWidth)
    }

    private var iconSize: CGFloat {
        max(24, UIFontMetrics(forTextStyle: .largeTitle).scaledValue(for: 24, compatibleWith: traitCollection))
    }

    init(frame: CGRect, name: String, icon: String?, actions: [OptionAction], themeOverride: Theme.ThemeType? = nil) {
        self.name = name
        self.icon = icon
        self.actions = actions
        self.themeOverride = themeOverride

        super.init(frame: frame)

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: MultipleActionView, _) in
            view.updateSize()
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func actionWasAdded() {
        let label = UILabel()
        label.font = UIFont.font(ofSize: 18, weight: .semibold, scalingWith: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.text = name
        label.textColor = AppTheme.mainTextColor(for: themeOverride)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        self.label = label

        if let icon, let image = UIImage(named: icon)?.tintedImage(ThemeColor.primaryIcon01(for: themeOverride)) {
            let imageView = UIImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 24),
                imageView.widthAnchor.constraint(equalToConstant: 24),
                label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 20),
            ])
            inlineConstraints = [
                label.topAnchor.constraint(equalTo: topAnchor),
                label.bottomAnchor.constraint(equalTo: bottomAnchor),
            ]
            self.imageView = imageView
        } else {
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            ])
            inlineConstraints = [
                label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                label.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            ]
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
            segmentedControl.widthAnchor.constraint(equalToConstant: segmentedControlWidth),
            segmentedControl.heightAnchor.constraint(equalToConstant: componentHeight),
        ])

        inlineConstraints += [
            trailingAnchor.constraint(equalTo: segmentedControl.trailingAnchor, constant: 20),
            segmentedControl.centerYAnchor.constraint(equalTo: centerYAnchor),
            segmentedControl.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 12),
        ]
        stackedConstraints = [
            label.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 20),
            segmentedControl.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            bottomAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 12),
        ]

        segmentedControl.addTarget(self, action: #selector(optionSelected), for: .valueChanged)

        updateSize()
        updateArrangement(forWidth: bounds.width)
    }

    override func layoutSubviews() {
        updateArrangement(forWidth: bounds.width)
        super.layoutSubviews()
    }

    func updateArrangement(forWidth width: CGFloat) {
        guard let label else { return }

        let labelWidth = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
        let leadingInset = imageView == nil ? 20 : 20 + iconSize + 20
        let isStacked = leadingInset + labelWidth + 12 + segmentedControlWidth + 20 > width
        guard isStacked != self.isStacked else { return }

        self.isStacked = isStacked
        NSLayoutConstraint.deactivate(isStacked ? inlineConstraints : stackedConstraints)
        NSLayoutConstraint.activate(isStacked ? stackedConstraints : inlineConstraints)
    }

    @objc private func optionSelected(_ sender: CustomSegmentedControl) {
        if let action = actions[safe: sender.selectedIndex] {
            action.action()
        }
    }

    private func updateSize() {
        imageView?.updateSizeConstraints(to: iconSize)
        setNeedsLayout()
    }
}
