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

        let resultSize = view.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        let width = view.superview?.bounds.width ?? view.bounds.width
        let minHeight: CGFloat = width < 350 ? 490 : 450
        let newSize = CGSize(width: min(Constants.Values.maxWidthForPopups, width), height: max(minHeight, resultSize.height))
        preferredContentSize = newSize
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
