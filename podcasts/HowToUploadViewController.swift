import UIKit

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

    @IBOutlet var howToShare1: ThemeableImageView! {
        didSet {
            howToShare1.imageNameFunc = AppTheme.howToFiles1ImageName
        }
    }

    @IBOutlet var secondInstructionLabel: ThemeableLabel! {
        didSet {
            secondInstructionLabel.style = .primaryText02
            secondInstructionLabel.text = L10n.howToUploadSecondInstruction
        }
    }

    @IBOutlet var howToShare2: ThemeableImageView! {
        didSet {
            howToShare2.imageNameFunc = AppTheme.howToFiles2ImageName
        }
    }

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
