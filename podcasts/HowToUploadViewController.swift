import SwiftUI

class HowToUploadViewController: UIViewController {
    @IBOutlet var explanationLabel: ThemeableLabel! {
        didSet {
            explanationLabel.style = .primaryText02
            explanationLabel.text = L10n.howToUploadExplanation
        }
    }

    @IBOutlet var firstInstructionLabel: ThemeableLabel! {
        didSet {
            firstInstructionLabel.style = .primaryText02
            firstInstructionLabel.text = L10n.howToUploadFirstInstruction
        }
    }

    @IBOutlet var howToShare1: ThemeableImageView!

    @IBOutlet var secondInstructionLabel: ThemeableLabel! {
        didSet {
            secondInstructionLabel.style = .primaryText02
            secondInstructionLabel.text = L10n.howToUploadSecondInstruction
            secondInstructionLabel.textAlignment = .center
        }
    }

    @IBOutlet var howToShare2: ThemeableImageView!

    @IBOutlet var summaryLabel: ThemeableLabel! {
        didSet {
            summaryLabel.style = .primaryText02
            summaryLabel.text = L10n.howToUploadSummary
        }
    }

    @IBOutlet var instructionBg1: ThemeableView! {
        didSet {
            instructionBg1.style = .primaryUi06
        }
    }

    @IBOutlet var instructionBg2: ThemeableView! {
        didSet {
            instructionBg2.style = .primaryUi06
        }
    }

    @IBOutlet var doneTap: ThemeableRoundedButton! {
        didSet {
            doneTap.setTitle(L10n.done.localizedCapitalized, for: .normal)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.filesHowToTitle
        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(doneTapped))
        closeButton.accessibilityLabel = L10n.accessibilityCloseDialog
        navigationItem.leftBarButtonItem = closeButton
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        let image1HostVC = UIHostingController(rootView: HowToShareImage1View().environmentObject(Theme.sharedTheme))
        guard let image1Subview = image1HostVC.view else { return }
        addChild(image1HostVC)
        howToShare1.addSubview(image1Subview)
        let image2HostVC = UIHostingController(rootView: HowToShareImage2View().environmentObject(Theme.sharedTheme))
        guard let image2Subview = image2HostVC.view else { return }
        addChild(image2HostVC)
        howToShare2.addSubview(image2Subview)
    }

    @IBAction func doneTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
