import UIKit

class CustomStepper: UIControl {
    private static let buttonWidth: CGFloat = 44
    private static let buttonHeight: CGFloat = 44

    private static let initialHoldTime: TimeInterval = 1
    private static let holdRepetition: TimeInterval = 0.15

    let minusButton = UIButton(type: .custom)
    let plusButton = UIButton(type: .custom)

    override var tintColor: UIColor! {
        didSet {
            minusButton.tintColor = tintColor
            plusButton.tintColor = tintColor
        }
    }

    var minimumValue: Int = 0 {
        didSet {
            if currentValue < minimumValue {
                currentValue = minimumValue
            }
        }
    }

    var maximumValue: Int = 200 {
        didSet {
            if currentValue > maximumValue {
                currentValue = maximumValue
            }
        }
    }

    var bigIncrements: Int = 1
    var smallIncrements: Int = 1
    var smallIncrementThreshold: Int = 1
    var currentValue: Int = 1 {
        didSet {
            accessibilityValue = "\(currentValue)"
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }

    private func setup() {
        isAccessibilityElement = true
        accessibilityTraits = [.adjustable]

        minusButton.setImage(UIImage(named: "player_effects_less"), for: .normal)
        minusButton.addTarget(self, action: #selector(lessTouchUp), for: .touchUpInside)
        minusButton.addTarget(self, action: #selector(touchCancelled), for: .touchCancel)
        minusButton.addTarget(self, action: #selector(touchCancelled), for: .touchUpOutside)
        minusButton.addTarget(self, action: #selector(lessTouchDown), for: .touchDown)
        addSubview(minusButton)

        minusButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            minusButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            minusButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            minusButton.widthAnchor.constraint(equalToConstant: Self.buttonWidth),
            minusButton.heightAnchor.constraint(equalToConstant: Self.buttonHeight)
        ])

        plusButton.setImage(UIImage(named: "player_effects_more"), for: .normal)
        plusButton.addTarget(self, action: #selector(moreTouchUp), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(touchCancelled), for: .touchCancel)
        plusButton.addTarget(self, action: #selector(touchCancelled), for: .touchUpOutside)
        plusButton.addTarget(self, action: #selector(moreTouchDown), for: .touchDown)
        addSubview(plusButton)

        plusButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            plusButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            plusButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: Self.buttonWidth),
            plusButton.heightAnchor.constraint(equalToConstant: Self.buttonHeight)
        ])
    }

    // MARK: - Hold Support

    private var holdTimer: Timer?
    @objc private func lessTouchDown() {
        holdTimer?.invalidate()

        holdTimer = Timer.scheduledTimer(withTimeInterval: Self.initialHoldTime, repeats: false, block: { [weak self] _ in
            if self?.currentValue == self?.minimumValue { return }

            self?.holdTimer = Timer.scheduledTimer(withTimeInterval: Self.holdRepetition, repeats: true, block: { _ in
                self?.performHoldLessDown()
            })
        })
    }

    private func performHoldLessDown() {
        if currentValue == minimumValue {
            holdTimer?.invalidate()

            return
        }

        currentValue = max(minimumValue, currentValue - negativeIncrement())
        sendActions(for: .valueChanged)
    }

    @objc private func moreTouchDown() {
        holdTimer?.invalidate()

        holdTimer = Timer.scheduledTimer(withTimeInterval: Self.initialHoldTime, repeats: false, block: { [weak self] _ in
            if self?.currentValue == self?.maximumValue { return }

            self?.holdTimer = Timer.scheduledTimer(withTimeInterval: Self.holdRepetition, repeats: true, block: { _ in
                self?.performHoldMoreDown()
            })
        })
    }

    private func performHoldMoreDown() {
        if currentValue == maximumValue {
            holdTimer?.invalidate()

            return
        }

        currentValue = min(maximumValue, currentValue + positiveIncrement())
        sendActions(for: .valueChanged)
    }

    @objc private func touchCancelled() {
        holdTimer?.invalidate()
    }

    // MARK: - Button Taps

    @objc private func lessTouchUp() {
        performDecrementAction()
    }

    private func performDecrementAction() {
        holdTimer?.invalidate()
        if currentValue == minimumValue { return }

        currentValue = max(minimumValue, currentValue - negativeIncrement())
        sendActions(for: .valueChanged)
    }

    @objc private func moreTouchUp() {
        performIncrementAction()
    }

    private func performIncrementAction() {
        holdTimer?.invalidate()
        if currentValue == maximumValue { return }

        currentValue = min(maximumValue, currentValue + positiveIncrement())
        sendActions(for: .valueChanged)
    }

    private func positiveIncrement() -> Int {
        currentValue < smallIncrementThreshold ? smallIncrements : bigIncrements
    }

    private func negativeIncrement() -> Int {
        currentValue <= smallIncrementThreshold ? smallIncrements : bigIncrements
    }

    // MARK: - Accessibility actions

    override func accessibilityIncrement() {
        performIncrementAction()
    }

    override func accessibilityDecrement() {
        performDecrementAction()
    }
}
