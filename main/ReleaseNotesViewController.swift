import UIKit

class ReleaseNotesViewController: UIViewController {
    @IBOutlet var versionLabel: ThemeableLabel!
    @IBOutlet var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Release Notes"
    }
}
