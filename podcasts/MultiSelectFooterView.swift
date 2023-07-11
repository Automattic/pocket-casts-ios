import MaterialComponents.MaterialBottomSheet
import UIKit

class MultiSelectFooterView: UIView, MultiSelectActionOrderDelegate {
    weak var delegate: MultiSelectActionDelegate?
    var getActionsFunc: (() -> [MultiSelectAction]) = Settings.multiSelectActions
    var setActionsFunc: (([MultiSelectAction]) -> Void) = Settings.updateMultiSelectActions
    var themeOverride: Theme.ThemeType? {
        didSet {
            selectedCountLabel.themeOverride = themeOverride
            handleThemeDidChange()
        }
    }

    @IBOutlet var contentView: UIView!
    @IBOutlet var blurView: UIVisualEffectView! {
        didSet {
            blurView.layer.cornerRadius = 18
        }
    }

    @IBOutlet var selectedCountLabel: ThemeableLabel! {
        didSet {
            selectedCountLabel.themeOverride = themeOverride
        }
    }

    @IBOutlet var moreButton: UIButton! {
        didSet {
            moreButton.backgroundColor = ThemeColor.primaryInteractive01()
            moreButton.setImage(UIImage(named: "more"), for: .normal)
            moreButton.tintColor = ThemeColor.primaryInteractive02()
            moreButton.layer.cornerRadius = 18
            moreButton.accessibilityLabel = L10n.accessibilityMoreActions
        }
    }

    @IBOutlet var leftActionButton: UIButton! {
        didSet {
            leftActionButton.backgroundColor = ThemeColor.primaryInteractive01()
            leftActionButton.setImage(UIImage(named: "more"), for: .normal)
            leftActionButton.tintColor = ThemeColor.primaryInteractive02()
            leftActionButton.layer.cornerRadius = 18
        }
    }

    @IBOutlet var rightActionButton: UIButton! {
        didSet {
            rightActionButton.backgroundColor = ThemeColor.primaryInteractive01()
            rightActionButton.setImage(UIImage(named: "more"), for: .normal)
            rightActionButton.tintColor = ThemeColor.primaryInteractive02()
            rightActionButton.layer.cornerRadius = 18
        }
    }

    @IBOutlet var containerView: UIView! {
        didSet {
            containerView.layer.cornerRadius = 18
            containerView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        }
    }

    @IBOutlet var statusLabel: ThemeableLabel!
    @IBOutlet var activityIndicator: ThemeLoadingIndicator!
    private var rightAction: MultiSelectAction?
    private var leftAction: MultiSelectAction?
    private var numberOfEpisodes: Int

    override init(frame: CGRect) {
        numberOfEpisodes = 0
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        numberOfEpisodes = 0
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("MultiSelectFooterView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    override var isHidden: Bool {
        get {
            super.isHidden
        }
        set(v) {
            super.isHidden = v
            if !isHidden {
                loadActions()
            }
        }
    }

    func setSelectedCount(count: Int) {
        guard count > 0 else {
            isHidden = true
            return
        }

        numberOfEpisodes = count
        isHidden = false
        selectedCountLabel.text = L10n.selectedCountFormat(count)
        selectedCountLabel.isHidden = false
        leftActionButton.isHidden = false
        rightActionButton.isHidden = false
        moreButton.isHidden = false

        statusLabel.isHidden = true
        activityIndicator.isHidden = true
        loadActions()
    }

    func setStatus(status: String) {
        statusLabel.text = status

        selectedCountLabel.isHidden = true
        leftActionButton.isHidden = true
        rightActionButton.isHidden = true
        moreButton.isHidden = true

        statusLabel.isHidden = false
        activityIndicator.isHidden = false
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }

    @IBAction func moreTapped(_ sender: Any) {
        guard let delegate = delegate else { return }

        let actions = getActionsFunc()

        let bottomSheet = MDCBottomSheetController(contentViewController: MultiSelectActionController(actions: actions, delegate: self, actionDelegate: delegate, numSelectedEpisodes: delegate.multiSelectedBaseEpisodes().count, setActionsFunc: setActionsFunc, themeOverride: themeOverride))
        let shapeGenerator = MDCCurvedRectShapeGenerator(cornerSize: CGSize(width: 8, height: 8))
        bottomSheet.setShapeGenerator(shapeGenerator, for: .preferred)
        bottomSheet.setShapeGenerator(shapeGenerator, for: .extended)
        bottomSheet.setShapeGenerator(shapeGenerator, for: .closed)
        bottomSheet.isScrimAccessibilityElement = true
        bottomSheet.scrimAccessibilityLabel = L10n.accessibilityDismiss
        delegate.multiSelectPresentingViewController().present(bottomSheet, animated: true, completion: nil)
    }

    @IBAction func rightActionTapped(_ sender: Any) {
        guard let delegate = delegate, let rightAction = rightAction else { return }
        MultiSelectHelper.performAction(rightAction, actionDelegate: delegate, view: rightActionButton)
    }

    @IBAction func leftActionTapped(_ sender: Any) {
        guard let delegate = delegate, let leftAction = leftAction else { return }
        MultiSelectHelper.performAction(leftAction, actionDelegate: delegate, view: leftActionButton)
    }

    @objc func handleThemeDidChange() {
        moreButton.backgroundColor = AppTheme.colorForStyle(.primaryInteractive01, themeOverride: themeOverride)
        moreButton.tintColor = AppTheme.colorForStyle(.primaryInteractive02, themeOverride: themeOverride)
        rightActionButton.backgroundColor = AppTheme.colorForStyle(.primaryInteractive01, themeOverride: themeOverride)
        rightActionButton.tintColor = AppTheme.colorForStyle(.primaryInteractive02, themeOverride: themeOverride)
        leftActionButton.backgroundColor = AppTheme.colorForStyle(.primaryInteractive01, themeOverride: themeOverride)
        leftActionButton.tintColor = AppTheme.colorForStyle(.primaryInteractive02, themeOverride: themeOverride)
    }

    func actionOrderChanged() {
        loadActions()
    }

    private func loadActions() {
        var actions = getActionsFunc()
        guard actions.count > 1, let actionDelegate = delegate else { return }

        if numberOfEpisodes > 1 {
            actions = actions.filter { $0 != .share }
        }

        let newLeftAction = MultiSelectHelper.invertActionIfRequired(action: actions[0], actionDelegate: actionDelegate)
        if leftAction != newLeftAction {
            leftAction = newLeftAction
            if let leftAction = leftAction {
                leftActionButton.setImage(UIImage(named: leftAction.iconName()), for: .normal)
                leftActionButton.accessibilityLabel = leftAction.title()
            }
        }

        let newRightAction = MultiSelectHelper.invertActionIfRequired(action: actions[1], actionDelegate: actionDelegate)
        if rightAction != newRightAction {
            rightAction = newRightAction

            if let rightAction = rightAction {
                rightActionButton.setImage(UIImage(named: rightAction.iconName()), for: .normal)
                rightActionButton.accessibilityLabel = rightAction.title()
            }
        }
    }
}
