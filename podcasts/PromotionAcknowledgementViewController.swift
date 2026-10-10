import UIKit

class PromotionAcknowledgementViewController: UIViewController {
    var serverMessage: String?
    @IBOutlet var logoImageView: ThemeableImageView! {
        didSet {
            logoImageView.imageNameFunc = AppTheme.pcPlusLogoVerticalImageName
        }
    }

    @IBOutlet var titleLabel: ThemeableLabel!
    @IBOutlet var descriptionLabel: ThemeableLabel! {
        didSet {
            descriptionLabel.style = .primaryText02
        }
    }

    @IBOutlet var doneButton: ThemeableRoundedButton! {
        didSet {
            doneButton.cornerRadius = 12
        }
    }

    @IBOutlet var handleView: ThemeableView! {
        didSet {
            handleView.style = .primaryUi05
        }
    }

    @IBAction func doneTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    init(serverMessage: String?) {
        self.serverMessage = serverMessage
        super.init(nibName: "PromotionAcknowledgementViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        (view as? ThemeableView)?.style = .primaryUi01

        if let message = serverMessage {
            descriptionLabel.text = message + "\n" + L10n.plusAccountTrialDetails
        } else {
            descriptionLabel.text = L10n.plusAccountTrialDetails
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        let availableWidth = view.superview?.bounds.width ?? view.bounds.width
        let width = min(Constants.Values.maxWidthForPopups, availableWidth)
        preferredContentSize = CGSize(width: width, height: contentHeight(width: width))
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        sheetPresentationController?.invalidateDetents()
    }

    /// A sheet detent that fits the content, so the text isn't clipped on short screens.
    var contentDetent: UISheetPresentationController.Detent {
        .custom(identifier: .init("promotionAcknowledgementContent")) { [weak self] context in
            guard let self else { return nil }
            let width = min(Constants.Values.maxWidthForPopups, self.view.bounds.width)
            return min(self.contentHeight(width: width), context.maximumDetentValue)
        }
    }

    private func contentHeight(width: CGFloat) -> CGFloat {
        let fittingSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let fittingHeight = view.systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
        let minHeight: CGFloat = width < 350 ? 490 : 450
        return max(minHeight, fittingHeight)
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
