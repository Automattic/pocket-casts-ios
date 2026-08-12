import UIKit

/// The events reported by `EpisodeListSearchController`. Every method is optional, so a header
/// without an action or an overflow button doesn't have to implement them.
protocol EpisodeListSearchControllerDelegate: AnyObject {
    /// Reports the search term once it stops changing for `searchDebounce`
    func episodeListSearchController(_ controller: EpisodeListSearchController, didChangeSearchTerm searchTerm: String)

    /// Reports a non-empty search term when the return key is tapped
    func episodeListSearchController(_ controller: EpisodeListSearchController, didSubmitSearchTerm searchTerm: String)

    /// Called when the search field becomes the first responder
    func episodeListSearchControllerDidBeginEditing(_ controller: EpisodeListSearchController)

    /// Called when the button next to the info label is tapped
    func episodeListSearchControllerDidTapAction(_ controller: EpisodeListSearchController)

    /// Called when the overflow button is tapped
    func episodeListSearchControllerDidTapOverflow(_ controller: EpisodeListSearchController)
}

extension EpisodeListSearchControllerDelegate {
    func episodeListSearchController(_ controller: EpisodeListSearchController, didChangeSearchTerm searchTerm: String) {}
    func episodeListSearchController(_ controller: EpisodeListSearchController, didSubmitSearchTerm searchTerm: String) {}
    func episodeListSearchControllerDidBeginEditing(_ controller: EpisodeListSearchController) {}
    func episodeListSearchControllerDidTapAction(_ controller: EpisodeListSearchController) {}
    func episodeListSearchControllerDidTapOverflow(_ controller: EpisodeListSearchController) {}
}

/// The search header displayed above the lists of the podcast page.
///
/// It's only responsible for the presentation: the delegate configures what it displays and
/// reacts to the events it reports.
class EpisodeListSearchController: SimpleNotificationsViewController, UITextFieldDelegate {
    weak var delegate: EpisodeListSearchControllerDelegate?

    // MARK: - Configuration

    /// The placeholder of the search field
    var placeholder = L10n.searchEpisodes {
        didSet {
            updatePlaceholder()
        }
    }

    /// Displayed below the search field, eg. the number of episodes
    var info: NSAttributedString? {
        didSet {
            infoLabel?.attributedText = info
        }
    }

    /// The title of the button next to the info label, which is hidden when it's `nil`
    var actionTitle: String? {
        didSet {
            updateActionButton()
        }
    }

    /// The accessibility label of the overflow button
    var overflowAccessibilityLabel: String? {
        didSet {
            guard let overflowAccessibilityLabel else { return }
            overflowButton?.accessibilityLabel = overflowAccessibilityLabel
        }
    }

    var isOverflowButtonEnabled = true {
        didSet {
            overflowButton?.isEnabled = isOverflowButtonEnabled
        }
    }

    /// Displays a spinner in place of the search icon
    var isLoading = false {
        didSet {
            updateLoadingIndicator()
        }
    }

    /// How long to wait after the last keystroke before reporting the search term.
    /// An empty term is always reported straight away.
    var searchDebounce: TimeInterval = 0

    var searchText: String {
        get { searchTextField?.text ?? "" }
        set {
            guard let searchTextField, searchTextField.text != newValue else { return }

            searchTextField.text = newValue
            updateClearButton()
        }
    }

    /// `true` while the search field has the keyboard focus
    var isSearchFieldActive: Bool {
        searchTextField?.isFirstResponder ?? false
    }

    // MARK: - Views

    @IBOutlet var roundedBackgroundView: UIView!
    @IBOutlet var searchTextField: UITextField! {
        didSet {
            searchTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
            searchTextField.font = UIFont.font(ofSize: 15, weight: .regular, scalingWith: .subheadline)
            searchTextField.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var searchIcon: UIImageView!
    @IBOutlet var loadingSpinner: ThemeLoadingIndicator!
    @IBOutlet var clearSearchBtn: UIButton!

    @IBOutlet var infoLabel: ThemeableLabel! {
        didSet {
            infoLabel.style = .primaryText02
            infoLabel.font = UIFont.font(ofSize: 14, weight: .regular, scalingWith: .footnote)
            infoLabel.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var actionButton: UIButton! {
        didSet {
            actionButton.titleLabel?.font = UIFont.font(ofSize: 15, weight: .regular, scalingWith: .footnote)
            actionButton.titleLabel?.adjustsFontForContentSizeCategory = true
            actionButton.titleLabel?.numberOfLines = 0
        }
    }

    @IBOutlet var overflowButton: ThemeSecondaryButton!

    @IBOutlet var dividerHeightConstraint: NSLayoutConstraint! {
        didSet {
            dividerHeightConstraint.constant = 1 / UIScreen.main.scale
        }
    }

    @IBOutlet var middleDividerHeightConstraint: NSLayoutConstraint! {
        didSet {
            middleDividerHeightConstraint.constant = 1 / UIScreen.main.scale
        }
    }

    private var searchTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        actionButton.titleLabel?.textAlignment = .center
        actionButton.titleLabel?.heightAnchor.constraint(equalTo: actionButton.heightAnchor).isActive = true

        infoLabel.attributedText = info
        overflowButton.isEnabled = isOverflowButtonEnabled
        if let overflowAccessibilityLabel {
            overflowButton.accessibilityLabel = overflowAccessibilityLabel
        }
        updateActionButton()
        updateClearButton()
        updateLoadingIndicator()

        themeChanged()
        addCustomObserver(Constants.Notifications.themeChanged, selector: #selector(themeChanged))
    }

    deinit {
        removeAllCustomObservers()
    }

    func hideKeyboard() {
        searchTextField?.resignFirstResponder()
    }

    func beginEditing() {
        searchTextField?.becomeFirstResponder()
    }

    // MARK: - Appearance

    @objc private func themeChanged() {
        view.backgroundColor = ThemeColor.primaryUi02()

        searchTextField.backgroundColor = UIColor.clear
        searchTextField.textColor = ThemeColor.primaryText02()
        searchTextField.keyboardAppearance = AppTheme.keyboardAppearance()
        updatePlaceholder()
        roundedBackgroundView.backgroundColor = ThemeColor.primaryField01()
        searchIcon.tintColor = ThemeColor.primaryIcon02()
        clearSearchBtn.tintColor = ThemeColor.primaryIcon02()
        actionButton.tintColor = ThemeColor.primaryInteractive01()
    }

    private func updatePlaceholder() {
        searchTextField?.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: ThemeColor.primaryText02(), .font: UIFont.font(ofSize: 15, weight: .regular, scalingWith: .subheadline)])
    }

    private func updateActionButton() {
        guard let actionButton else { return }

        actionButton.isHidden = actionTitle == nil

        guard let actionTitle else { return }

        UIView.performWithoutAnimation {
            actionButton.setTitle(actionTitle, for: .normal)
            actionButton.layoutIfNeeded()
        }
    }

    private func updateClearButton() {
        clearSearchBtn?.isHidden = searchText.isEmpty
    }

    private func updateLoadingIndicator() {
        guard let loadingSpinner else { return }

        searchIcon.isHidden = isLoading
        if isLoading {
            loadingSpinner.startAnimating()
        } else {
            loadingSpinner.stopAnimating()
        }
    }

    // MARK: - Search

    @objc private func textFieldDidChange() {
        updateClearButton()
        cancelSearchTimer()

        let searchTerm = searchText
        guard !searchTerm.isEmpty, searchDebounce > 0 else {
            delegate?.episodeListSearchController(self, didChangeSearchTerm: searchTerm)
            return
        }

        searchTimer = Timer.scheduledTimer(timeInterval: searchDebounce, target: self, selector: #selector(searchTimerFired), userInfo: nil, repeats: false)
    }

    @objc private func searchTimerFired() {
        searchTimer = nil
        delegate?.episodeListSearchController(self, didChangeSearchTerm: searchText)
    }

    private func cancelSearchTimer() {
        searchTimer?.invalidate()
        searchTimer = nil
    }

    @IBAction func clearSearchTapped(_ sender: Any) {
        cancelSearchTimer()
        searchText = ""
        isLoading = false
        delegate?.episodeListSearchController(self, didChangeSearchTerm: "")
    }

    @IBAction func actionTapped(_ sender: Any) {
        delegate?.episodeListSearchControllerDidTapAction(self)
    }

    @IBAction func overflowTapped(_ sender: Any) {
        delegate?.episodeListSearchControllerDidTapOverflow(self)
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.episodeListSearchControllerDidBeginEditing(self)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidStart)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidEnd)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        let searchTerm = searchText
        guard !searchTerm.isEmpty else { return true }

        cancelSearchTimer()
        delegate?.episodeListSearchController(self, didSubmitSearchTerm: searchTerm)

        return true
    }
}
