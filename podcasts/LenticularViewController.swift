import UIKit

class LenticularViewController: UIViewController {
    private var overlayView: LenticularOverlayView?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.isUserInteractionEnabled = false
        overlayView = LenticularOverlayView(frame: view.bounds)
        if let overlayView = overlayView {
            overlayView.backgroundColor = UIColor.clear

            view.addSubview(overlayView)
            overlayView.anchorToAllSidesOf(view: view)
            overlayView.transform = CGAffineTransform(rotationAngle: 1.5708)
            overlayView.isUserInteractionEnabled = false
        }
        view.frame = UIScreen.main.bounds
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        overlayView?.frame = view.bounds
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
