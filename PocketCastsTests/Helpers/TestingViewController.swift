import UIKit

class TestingViewController: UIViewController {
    @IBOutlet var outerRing: UIView!
    @IBOutlet var innerRing: UIView!

    override func viewWillAppear(_ animated: Bool) {
        // Animate the logo to make you anxious while tests are running
        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut, .autoreverse, .repeat], animations: {
            self.innerRing.alpha = 0.3
        }, completion: nil)

        UIView.animate(withDuration: 0.4, delay: 0.15, options: [.curveEaseInOut, .autoreverse, .repeat], animations: {
            self.outerRing.alpha = 0.3
        }, completion: nil)
    }
}
