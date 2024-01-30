import UIKit

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

    static let defaultHeight: CGFloat = 54
    static let peekAmountBeforeAutoOpen: CGFloat = 20

    var shouldShowCancelButton = true
    var cancelButtonShowing = false
    var searchControllerTopConstant: NSLayoutConstraint?
    var searchDebounce = 1.seconds
    var searchTimer: Timer?

    var placeholderText = L10n.searchLabel

    var backgroundColorOverride: UIColor?

    var startWithToolbarHidden = true

    weak var searchDelegate: PCSearchBarDelegate?

    private var isVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()

        updateColors()
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(searchRequest), name: Constants.Notifications.podcastSearchRequest, object: nil)
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

        let placeholderColor = backgroundColorOverride == nil ? ThemeColor.secondaryText02() : ThemeColor.primaryText02()
        searchTextField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])

        let iconColor = backgroundColorOverride == nil ? ThemeColor.secondaryIcon02() : ThemeColor.primaryIcon02()
        searchIcon.tintColor = iconColor
        clearSearchBtn.tintColor = iconColor
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
}
