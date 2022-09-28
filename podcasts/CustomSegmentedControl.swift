import UIKit

struct SegmentedAction {
    // The un-written (and yet written) contract here is that you can specify an icon or a title, but not both. If you do you're going to be severely underwhelmed
    init(icon: UIImage, accessibilityLabel: String) {
        self.icon = icon
        title = nil
        self.accessibilityLabel = accessibilityLabel
    }

    init(title: String) {
        icon = nil
        self.title = title
        accessibilityLabel = title
    }

    let icon: UIImage?
    let title: String?
    let accessibilityLabel: String
}

class CustomSegmentedControl: UIControl {
    static let separatorWidth: CGFloat = 2

    // MARK: - Public properties

    var lineColor = UIColor.blue {
        didSet {
            updateColors()
        }
    }

    var selectedBgColor = UIColor.blue {
        didSet {
            updateColors()
        }
    }

    var selectedItemColor = UIColor.black {
        didSet {
            updateColors()
        }
    }

    var unselectedBgColor = UIColor.clear {
        didSet {
            updateColors()
        }
    }

    var unselectedItemColor = UIColor.red {
        didSet {
            updateColors()
        }
    }

    var selectedIndex = 0 {
        didSet {
            if oldValue != selectedIndex {
                indexDidChange(previousValue: oldValue)
            }
        }
    }

    private var actionViews = [UIView]()
    private var separatorViews = [UIView]()
    private var itemViews = [UIView]()

    private var actionCount = 0
    private var titleFont = UIFont.systemFont(ofSize: 15, weight: .bold)

    public func setActions(_ actions: [SegmentedAction]) {
        clearCurrentActions()

        actionCount = actions.count
        setup(actions: actions)

        layoutIfNeeded()
    }

    private func clearCurrentActions() {
        actionViews.forEach { view in
            view.removeFromSuperview()
        }
        actionViews.removeAll()

        separatorViews.forEach { view in
            view.removeFromSuperview()
        }
        separatorViews.removeAll()

        itemViews.removeAll()
    }

    private func indexDidChange(previousValue: Int) {
        // if we animate this in a future version, we should be able to do it here
        updateColors()
        updateAccessibilityTraits()
    }

    private func setup(actions: [SegmentedAction]) {
        layer.cornerRadius = 8
        layer.borderWidth = 2

        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        var previousSeparator: UIView?
        for (index, action) in actions.enumerated() {
            let actionView = UIView()
            actionView.translatesAutoresizingMaskIntoConstraints = false
            actionView.accessibilityLabel = action.accessibilityLabel
            actionView.isAccessibilityElement = true
            actionView.isUserInteractionEnabled = true
            addSubview(actionView)

            let widthMultiplier = (1.0 / CGFloat(actionCount))
            let willHaveTrailingSeperator = (index < actions.count - 1)
            NSLayoutConstraint.activate([
                actionView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: widthMultiplier),
                actionView.topAnchor.constraint(equalTo: topAnchor),
                actionView.bottomAnchor.constraint(equalTo: bottomAnchor),
                actionView.leadingAnchor.constraint(equalTo: previousSeparator?.trailingAnchor ?? leadingAnchor)
            ])
            if index == actions.count - 1 {
                actionView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            }

            // set up touch handling
            let touchHandler = UITapGestureRecognizer(target: self, action: #selector(segmentTapped(_:)))
            actionView.addGestureRecognizer(touchHandler)

            // add icon or text
            if let icon = action.icon {
                let iconView = TintableImageView(image: icon)
                iconView.contentMode = .center
                actionView.addSubview(iconView)
                iconView.anchorToAllSidesOf(view: actionView)

                itemViews.append(iconView)
            } else {
                let label = UILabel()
                label.text = action.title
                label.textAlignment = .center
                label.font = titleFont
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.7
                actionView.addSubview(label)
                label.anchorToAllSidesOf(view: actionView, padding: 4)

                itemViews.append(label)
            }
            actionViews.append(actionView)

            // add seperator if required
            if willHaveTrailingSeperator {
                let separator = UIView()
                separator.translatesAutoresizingMaskIntoConstraints = false

                addSubview(separator)
                NSLayoutConstraint.activate([
                    separator.widthAnchor.constraint(equalToConstant: CustomSegmentedControl.separatorWidth),
                    separator.topAnchor.constraint(equalTo: topAnchor, constant: 2),
                    separator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
                    separator.leadingAnchor.constraint(equalTo: actionView.trailingAnchor)
                ])
                separatorViews.append(separator)

                previousSeparator = separator
            }
        }

        updateColors()
        updateAccessibilityTraits()
    }

    private func updateAccessibilityTraits() {
        for (index, actionView) in actionViews.enumerated() {
            if index == selectedIndex {
                actionView.accessibilityTraits = [.button, .selected]
            } else {
                actionView.accessibilityTraits = [.button]
            }
        }
    }

    private func updateColors() {
        for (index, view) in actionViews.enumerated() {
            view.backgroundColor = selectedIndex == index ? selectedBgColor : unselectedBgColor
        }

        separatorViews.forEach { $0.backgroundColor = lineColor }

        // Joe requested that the lines don't show up next to the selected item, so handle hiding them hear
        if selectedIndex == 0 {
            separatorViews.first?.backgroundColor = UIColor.clear
        } else if selectedIndex == (actionViews.count - 1) {
            separatorViews.last?.backgroundColor = UIColor.clear
        } else {
            separatorViews[safe: selectedIndex - 1]?.backgroundColor = UIColor.clear
            separatorViews[safe: selectedIndex]?.backgroundColor = UIColor.clear
        }

        for (index, itemView) in itemViews.enumerated() {
            let color = selectedIndex == index ? selectedItemColor : unselectedItemColor
            if let itemView = itemView as? UILabel {
                itemView.textColor = color
            } else {
                itemView.tintColor = color
            }
        }

        layer.borderColor = lineColor.cgColor
    }

    @objc private func segmentTapped(_ recognizer: UITapGestureRecognizer) {
        let locationTapped = recognizer.location(in: self)
        let segmentTapped = Int(locationTapped.x / (bounds.width / CGFloat(actionCount)))

        selectedIndex = segmentTapped
        sendActions(for: .valueChanged)
    }
}
