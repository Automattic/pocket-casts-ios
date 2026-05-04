import UIKit
import PocketCastsUtils

protocol PCSearchBarDelegate: AnyObject {
    func searchDidBegin()
    func searchDidEnd()
    func searchWasCleared()
    func searchTermChanged(_ searchTerm: String)
    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void))
}

class PCSearchBarController: UIViewController {
    @IBOutlet var roundedBackgroundView: UIView!
    @IBOutlet var searchTextField: UITextField! {
        didSet {
            searchTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        }
    }

    @IBOutlet var searchIcon: UIImageView!
    @IBOutlet var cancelButton: UIButton! {
        didSet {
            cancelButton.setTitle(L10n.cancel, for: .normal)
            cancelButton.titleLabel?.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var loadingSpinner: ThemeLoadingIndicator!

    @IBOutlet var roundedBgTrailingSpaceParent: NSLayoutConstraint!
    @IBOutlet var roundedBgTrailingSpaceToCancel: NSLayoutConstraint! {
        didSet {
            roundedBgTrailingSpaceToCancel.isActive = false // the cancel button is hidden by default
        }
    }

    @IBOutlet var clearSearchBtn: UIButton!

    private static let pillHeight: CGFloat = 32
    private static let pillBottomInset: CGFloat = 16

    static var defaultHeight: CGFloat {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)
        let base = pillHeight + pillBottomInset
        return max(base, metric.scaledValue(for: base))
    }

    static let peekAmountBeforeAutoOpen: CGFloat = 20

    var shouldShowCancelButton = true
    var cancelButtonShowing = false

    /// When set, the scrolling extension drives this constraint's `constant` between `0` and
    /// `defaultHeight` to collapse/expand the bar in place — the bar's top stays anchored to
    /// the safe area, and the pill, icons and placeholder fade and shrink together.
    var searchControllerHeightConstraint: NSLayoutConstraint?

    var searchDebounce = 1.seconds
    var searchTimer: Timer?

    var placeholderText = L10n.searchLabel {
        didSet {
            if isViewLoaded {
                updatePlaceholderColor()
            }
        }
    }

    var backgroundColorOverride: UIColor?

    var startWithToolbarHidden = true

    weak var searchDelegate: PCSearchBarDelegate?

    private var isVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        updateColors()
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(searchRequest), name: Constants.Notifications.podcastSearchRequest, object: nil)
        updateSize()
        updateCollapseAppearance()
    }

    func updateCollapseAppearance() {
        let height = searchControllerHeightConstraint?.constant ?? Self.defaultHeight
        let progress = min(1, max(0, height / Self.defaultHeight))
        // Pill itself shrinks in place; contents fade on a steeper curve so the text/icons are
        // gone well before the pill finishes collapsing — closer to the native bar.
        let contentAlpha = max(0, progress * 2 - 1)
        searchIcon.alpha = contentAlpha
        searchTextField.alpha = contentAlpha
        clearSearchBtn.alpha = contentAlpha
        loadingSpinner.alpha = contentAlpha
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isVisible = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isVisible = false
    }

    @objc private func themeDidChange() {
        updateColors()
    }

    @objc private func searchRequest(notification: Notification) {
        if isVisible, let searchTerm = notification.object as? String {
            searchTextField.text = searchTerm
            clearSearchBtn.isHidden = false
            view.endEditing(true)
        }
    }

    private func updateColors() {
        view.backgroundColor = backgroundColorOverride ?? ThemeColor.secondaryUi01()
        searchTextField.backgroundColor = UIColor.clear
        searchTextField.keyboardAppearance = AppTheme.keyboardAppearance()
        roundedBackgroundView.backgroundColor = backgroundColorOverride == nil ? ThemeColor.secondaryField01() : ThemeColor.primaryField01()

        let textColor = backgroundColorOverride == nil ? ThemeColor.secondaryText01() : ThemeColor.primaryText01()
        searchTextField.textColor = textColor
        cancelButton.setTitleColor(textColor, for: .normal)

        updatePlaceholderColor()

        let iconColor = backgroundColorOverride == nil ? ThemeColor.secondaryIcon02() : ThemeColor.primaryIcon02()
        searchIcon.tintColor = iconColor
        clearSearchBtn.tintColor = iconColor
    }

    private func updatePlaceholderColor() {
        let placeholderColor = backgroundColorOverride == nil ? ThemeColor.secondaryText02() : ThemeColor.primaryText02()
        searchTextField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
    }

    @IBAction func cancelTapped(_ sender: Any) {
        clearSearchBtn.isHidden = true
        searchTextField.text = nil
        searchTextField.resignFirstResponder()
        hideCancelButton()

        searchDelegate?.searchDidEnd()
    }

    @IBAction func clearSearchTapped(_ sender: Any) {
        searchTextField.text = ""
        clearSearchBtn.isHidden = true

        searchDelegate?.searchWasCleared()
    }

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)
        let imageSize = max(16, metric.scaledValue(for: 16))
        searchIcon.updateSizeConstraints(to: imageSize)

        let clearSearchSize = max(22, metric.scaledValue(for: 22))
        clearSearchBtn.updateSizeConstraints(to: clearSearchSize)

        view.updateSizeConstraints(to: Self.defaultHeight)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory else { return }
        updateSize()
    }
}
