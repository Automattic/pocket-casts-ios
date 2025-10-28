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

    override var isAccessibilityElement: Bool {
        get { false }
        set { }
    }

    private var actionViews = [SegmentView]()
    private var separatorViews = [UIView]()
    private var itemViews = [UIView]()

    private var actionCount = 0
    private var titleFont = UIFont.systemFont(ofSize: 15, weight: .bold)
    private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()

    private final class SegmentView: UIView {
        let index: Int
        private let selectHandler: (Int) -> Void

        init(index: Int, accessibilityLabel: String, selectHandler: @escaping (Int) -> Void) {
            self.index = index
            self.selectHandler = selectHandler
            super.init(frame: .zero)
            isAccessibilityElement = true
            accessibilityTraits = [.button]
            self.accessibilityLabel = accessibilityLabel
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func accessibilityActivate() -> Bool {
            selectHandler(index)
            return true
        }

        func updateSelectionState(isSelected: Bool) {
            if isSelected {
                accessibilityTraits.insert(.selected)
            } else {
                accessibilityTraits.remove(.selected)
            }
        }
    }

    public func setActions(_ actions: [SegmentedAction]) {
        clearCurrentActions()

        self.actions = actions
        actionCount = actions.count
        clampSelectedIndexIfNeeded()
        setup(actions: actions)

        layoutIfNeeded()
    }

    private func clearCurrentActions() {
        actionViews.forEach { $0.removeFromSuperview() }
        actionViews.removeAll()

        separatorViews.forEach { $0.removeFromSuperview() }
        separatorViews.removeAll()

        itemViews.removeAll()
    }

    private func indexDidChange(previousValue: Int) {
        updateColors()
        updateSegmentAccessibilityStates()
        announceAccessibilitySelection()
        provideSelectionFeedbackIfNeeded()
    }

    private func setup(actions: [SegmentedAction]) {
        layer.cornerRadius = 8
        layer.borderWidth = 2

        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        var previousSeparator: UIView?
        for (index, action) in actions.enumerated() {
            let segmentView = SegmentView(index: index, accessibilityLabel: action.accessibilityLabel, selectHandler: { [weak self] index in
                self?.selectSegment(at: index)
            })
            segmentView.translatesAutoresizingMaskIntoConstraints = false
            segmentView.isUserInteractionEnabled = true
            addSubview(segmentView)

            let widthMultiplier = (1.0 / CGFloat(actionCount))
            let willHaveTrailingSeperator = (index < actions.count - 1)
            NSLayoutConstraint.activate([
                segmentView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: widthMultiplier),
                segmentView.topAnchor.constraint(equalTo: topAnchor),
                segmentView.bottomAnchor.constraint(equalTo: bottomAnchor),
                segmentView.leadingAnchor.constraint(equalTo: previousSeparator?.trailingAnchor ?? leadingAnchor)
            ])
            if index == actions.count - 1 {
                segmentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            }

            // set up touch handling
            let touchHandler = UITapGestureRecognizer(target: self, action: #selector(segmentTapped(_:)))
            segmentView.addGestureRecognizer(touchHandler)

            // add icon or text
            if let icon = action.icon {
                let iconView = TintableImageView(image: icon)
                iconView.contentMode = .center
                segmentView.addSubview(iconView)
                iconView.anchorToAllSidesOf(view: segmentView)

                itemViews.append(iconView)
            } else {
                let label = UILabel()
                label.text = action.title
                label.textAlignment = .center
                label.font = titleFont
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.7
                segmentView.addSubview(label)
                label.anchorToAllSidesOf(view: segmentView, padding: 4)

                itemViews.append(label)
            }
            actionViews.append(segmentView)

            // add seperator if required
            if willHaveTrailingSeperator {
                let separator = UIView()
                separator.translatesAutoresizingMaskIntoConstraints = false

                addSubview(separator)
                NSLayoutConstraint.activate([
                    separator.widthAnchor.constraint(equalToConstant: CustomSegmentedControl.separatorWidth),
                    separator.topAnchor.constraint(equalTo: topAnchor, constant: 2),
                    separator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
                    separator.leadingAnchor.constraint(equalTo: segmentView.trailingAnchor)
                ])
                separatorViews.append(separator)

                previousSeparator = separator
            }
        }

        updateColors()
        setupAccessibility()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            selectionFeedbackGenerator.prepare()
        }
    }

    private func setupAccessibility() {
        isAccessibilityElement = false
        accessibilityTraits = []
        updateSegmentAccessibilityStates()
    }

    private func updateColors() {
        for (index, view) in actionViews.enumerated() {
            let isSelected = selectedIndex == index
            view.backgroundColor = isSelected ? selectedBgColor : unselectedBgColor
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

    private func updateSegmentAccessibilityStates() {
        for (index, segment) in actionViews.enumerated() {
            segment.updateSelectionState(isSelected: index == selectedIndex)
        }
    }

    private func announceAccessibilitySelection() {
        guard UIAccessibility.isVoiceOverRunning,
              window != nil,
              !isHidden,
              alpha > 0,
              !accessibilityElementsHidden,
              selectedIndex >= 0,
              selectedIndex < actions.count else {
            return
        }

        let label = actions[selectedIndex].accessibilityLabel
        guard !label.isEmpty else { return }

        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: label)
        }
    }

    private func provideSelectionFeedbackIfNeeded() {
        guard window != nil else { return }

        selectionFeedbackGenerator.selectionChanged()
        selectionFeedbackGenerator.prepare()
    }

    @objc private func segmentTapped(_ recognizer: UITapGestureRecognizer) {
        let locationTapped = recognizer.location(in: self)
        selectSegment(atLocation: locationTapped)
    }

    // MARK: - Accessibility Support

    private var actions: [SegmentedAction] = []

    func setActionsWithAccessibility(_ actions: [SegmentedAction]) {
        setActions(actions)
    }

    private func clampSelectedIndexIfNeeded() {
        if actions.isEmpty {
            if selectedIndex != 0 {
                selectedIndex = 0
            }
            return
        }

        let validRange = 0...(actions.count - 1)
        let clampedValue = (selectedIndex...selectedIndex).clamped(to: validRange).lowerBound
        if clampedValue != selectedIndex {
            selectedIndex = clampedValue
        }
    }

    private func selectSegment(atLocation point: CGPoint) {
        guard actionCount > 0, bounds.width > 0 else { return }

        let segmentWidth = bounds.width / CGFloat(actionCount)
        guard segmentWidth > 0 else { return }

        let rawIndex = Int(point.x / segmentWidth)
        selectSegment(at: rawIndex)
    }

    private func selectSegment(at index: Int) {
        guard actionCount > 0 else { return }

        let clampedIndex = max(0, min(actionCount - 1, index))
        guard clampedIndex != selectedIndex else { return }

        selectedIndex = clampedIndex
        sendActions(for: .valueChanged)
    }
}
