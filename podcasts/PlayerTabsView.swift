import PocketCastsUtils
import UIKit

protocol PlayerTabDelegate: AnyObject {
    func didSwitchToTab(index: Int)
}

enum PlayerTabs: Int {
    case nowPlaying
    case showNotes
    case chapters

    var description: String {
        switch self {
        case .nowPlaying:
            return L10n.nowPlaying
        case .showNotes:
            return L10n.playerShowNotesTitle
        case .chapters:
            return L10n.chapters
        }
    }

    var shortDescription: String {
        switch self {
        case .nowPlaying:
            return L10n.nowPlayingShortTitle
        default:
            return description
        }
    }
}

class PlayerTabsView: UIScrollView {
    var tabs: [PlayerTabs] = [.nowPlaying] {
        didSet {
            updateTabs()
        }
    }

    var currentTab = 0 {
        didSet {
            animateTabChange(fromIndex: oldValue, toIndex: currentTab)

            if oldValue != currentTab, let tab = PlayerTabs(rawValue: currentTab) {
                trackTabChanged(tab: tab)
            }

            if currentTab == 1 {
                AnalyticsHelper.playerShowNotesOpened()
            } else if currentTab == 2 {
                AnalyticsHelper.chaptersOpened()
            }
        }
    }

    var leadingEdgePullDistance: CGFloat = 0 {
        didSet {
            updateLine()
        }
    }

    var trailingEdgePullDistance: CGFloat = 0 {
        didSet {
            updateLine()
        }
    }

    weak var tabDelegate: PlayerTabDelegate?

    private let lineHeight: CGFloat = 2
    private let lineLayer = CAShapeLayer()
    private let lineOffset: CGFloat = 8

    private lazy var tabsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = TabConstants.spacing

        return stackView
    }()

    // Fade Layers
    private lazy var fadeLeading = {
        FadeOutLayer(fadePosition: .leading)
    }()

    private lazy var fadeTrailing = {
        FadeOutLayer(fadePosition: .trailing)
    }()

    func setup() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        clipsToBounds = true

        configureLine()
        updateTabs()

        addSubview(tabsStackView)
        tabsStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tabsStackView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            tabsStackView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            tabsStackView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
            tabsStackView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            tabsStackView.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor)
        ])

        layer.addSublayer(fadeLeading)
        layer.addSublayer(fadeTrailing)
    }

    func themeDidChange() {
        updateTabs()

        fadeLeading.updateColors()
        fadeTrailing.updateColors()
    }

    var lastLayedOutWidth: CGFloat = 0
    override func layoutSubviews() {
        super.layoutSubviews()

        updateFadeLayers()

        let currentWidth = bounds.width
        if lastLayedOutWidth == currentWidth { return }

        lastLayedOutWidth = currentWidth
        updateTabs()
    }

    private func updateTabs() {
        tabsStackView.removeAllSubviews()

        for (index, tab) in tabs.enumerated() {
            let button = UIButton(type: .custom)
            button.isPointerInteractionEnabled = true
            button.titleLabel?.font = TabConstants.titleFont

            let titleColor = index == currentTab ? ThemeColor.playerContrast01() : ThemeColor.playerContrast02()
            button.setTitleColor(titleColor, for: .normal)

            let title = tab.description
            button.setTitle(title, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

            tabsStackView.addArrangedSubview(button)
        }

        layoutIfNeeded()
        updateLine()
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        let tabIndex = sender.tag

        currentTab = tabIndex
        tabDelegate?.didSwitchToTab(index: currentTab)
    }

    private func configureLine() {
        lineLayer.lineWidth = 1
        let contrast01 = ThemeColor.playerContrast01().cgColor
        lineLayer.fillColor = contrast01
        lineLayer.strokeColor = contrast01

        lineLayer.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 24, height: lineHeight)).cgPath
        lineLayer.lineCap = CAShapeLayerLineCap.round

        layer.addSublayer(lineLayer)
    }

    private func updateLine() {
        lineLayer.path = UIBezierPath(rect: lineRectForTab(index: currentTab)).cgPath
    }

    func animateBackToNonCompressed() {
        let currentLine = lineLayer.path
        let newLine = lineRectForTab(index: currentTab, ignoreLeadingTrailing: true)

        //  line moving animation
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = currentLine
        animation.toValue = UIBezierPath(rect: newLine).cgPath

        animation.duration = Constants.Animation.defaultAnimationTime
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.leadingEdgePullDistance = 0
            self.trailingEdgePullDistance = 0
            self.lineLayer.removeAllAnimations()
        }
        lineLayer.add(animation, forKey: "animatePath")
        CATransaction.commit()
    }

    private func animateTabChange(fromIndex: Int, toIndex: Int) {
        let previousLine = lineRectForTab(index: fromIndex)
        let newLine = lineRectForTab(index: toIndex)

        //  line moving animation
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = UIBezierPath(rect: previousLine).cgPath
        animation.toValue = UIBezierPath(rect: newLine).cgPath

        animation.duration = Constants.Animation.defaultAnimationTime
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false

        // text color animation
        if let fromTab = tabsStackView.arrangedSubviews[safe: fromIndex] as? UIButton {
            UIView.transition(with: fromTab, duration: Constants.Animation.defaultAnimationTime, options: .transitionCrossDissolve, animations: {
                fromTab.setTitleColor(ThemeColor.playerContrast02(), for: .normal)
            }, completion: nil)
        }

        if let toTab = tabsStackView.arrangedSubviews[safe: toIndex] as? UIButton {
            UIView.transition(with: toTab, duration: Constants.Animation.defaultAnimationTime, options: .transitionCrossDissolve, animations: {
                toTab.setTitleColor(ThemeColor.playerContrast01(), for: .normal)
            }, completion: nil)

            // Scroll the button into view, but make sure it clears the fade
            scrollRectToVisible(toTab.frame.insetBy(dx: -TabConstants.fadeSize, dy: 0), animated: true)
        }

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.updateLine()
            self.lineLayer.removeAllAnimations()
        }
        lineLayer.add(animation, forKey: "animatePath")
        CATransaction.commit()
    }

    private func lineRectForTab(index: Int, ignoreLeadingTrailing: Bool = false) -> CGRect {
        guard let tab = tabsStackView.arrangedSubviews[safe: index] else { return CGRect.zero }

        let tabRect = convert(tab.frame, from: tab.superview)
        if !ignoreLeadingTrailing, leadingEdgePullDistance > 0 || trailingEdgePullDistance > 0 {
            let width = tabRect.width - min(tabRect.width * 0.9, (leadingEdgePullDistance + trailingEdgePullDistance) / 3)
            if leadingEdgePullDistance > 0 {
                return CGRect(x: tabRect.minX, y: tabRect.maxY - lineOffset, width: width, height: lineHeight)
            } else {
                return CGRect(x: tabRect.minX + (tabRect.width - width), y: tabRect.maxY - lineOffset, width: width, height: lineHeight)
            }
        } else {
            return CGRect(x: tabRect.minX, y: tabRect.maxY - lineOffset, width: tabRect.width, height: lineHeight)
        }
    }

    private enum TabConstants {
        static let titleFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        static let spacing: CGFloat = 14
        static let fadeSize: CGFloat = 50
    }
}

// MARK: - Private: Scroll Fading

private extension PlayerTabsView {
    private func updateFadeLayers() {
        let offset = contentOffset.x
        let size = CGSize(width: TabConstants.fadeSize, height: bounds.height)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fadeLeading.frame = .init(origin: .init(x: offset, y: 0), size: size)
        fadeTrailing.frame = .init(origin: .init(x: offset + bounds.width - TabConstants.fadeSize, y: 0), size: size)
        CATransaction.commit()

        fadeLeading.opacity = contentOffset.x > 0 ? 1 : 0
        fadeTrailing.opacity = (contentOffset.x + bounds.width) < contentSize.width ? 1 : 0
    }

    private class FadeOutLayer: CAGradientLayer {
        enum FadePosition {
            case leading, trailing
        }

        var fadePosition: FadePosition = .leading

        init(fadePosition: FadePosition) {
            self.fadePosition = fadePosition

            super.init()

            updateColors()

            switch fadePosition {
            case .leading:
                startPoint = .init(x: 1, y: 0)
                endPoint = .zero

            case .trailing:
                startPoint = .zero
                endPoint = .init(x: 1, y: 0)
            }
        }

        func updateColors() {
            let color = PlayerColorHelper.playerBackgroundColor01()

            colors = [
                color.withAlphaComponent(0).cgColor,
                color.cgColor
            ]
        }

        override init(layer: Any) {
            if let layer = layer as? Self {
                fadePosition = layer.fadePosition
            }

            super.init(layer: layer)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: - Private: Analytics

private extension PlayerTabsView {
    func trackTabChanged(tab: PlayerTabs) {
        let tabName: String
        switch tab {
        case .nowPlaying:
            tabName = "now_playing"
        case .showNotes:
            tabName = "show_notes"
        case .chapters:
            tabName = "chapters"
        }

        Analytics.track(.playerTabSelected, properties: ["tab": tabName])
    }
}
