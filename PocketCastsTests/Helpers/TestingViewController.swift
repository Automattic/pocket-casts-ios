import UIKit

class TestingViewController: UIViewController {
    @IBOutlet weak var outerRing: UIView!
    @IBOutlet weak var innerRing: UIView!

    override func viewWillAppear(_ animated: Bool) {
        // Animate the logo
        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut, .autoreverse, .repeat], animations: {
            self.innerRing.alpha = 0.3
        }, completion: nil)

        UIView.animate(withDuration: 0.4, delay: 0.15, options: [.curveEaseInOut, .autoreverse, .repeat], animations: {
            self.outerRing.alpha = 0.3
        }, completion: nil)
    }

}
