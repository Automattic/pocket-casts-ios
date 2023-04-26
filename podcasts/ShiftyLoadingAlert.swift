import UIKit

class ShiftyLoadingAlert {
    private var titleToSet = ""
    var title = "" {
        didSet {
            if let alertController = alertController {
                alertController.title = "\(title)\n\n\n"
            }
        }
    }

    var progress = 0 as CGFloat {
        didSet {
            if let progressIndicator = progressIndicator {
                progressIndicator.progress = progress
            }
        }
    }

    private let indicatorSize = 30 as CGFloat

    private var progressIndicator: AngularProgressIndicator?
    private var alertController: UIAlertController?

    init(title: String) {
        titleToSet = title
        alertController = UIAlertController(title: "", message: nil, preferredStyle: UIAlertController.Style.alert)
    }

    func showAlert(_ presentingController: UIViewController, hasProgress: Bool, completion: (() -> Void)?) {
        title = titleToSet
        if hasProgress {
            progressIndicator = AngularProgressIndicator(size: CGSize(width: indicatorSize, height: indicatorSize), lineWidth: 2.0)
            alertController!.view.addSubview(progressIndicator!)

            presentingController.present(alertController!, animated: true) { () in
                let parentFrame = self.alertController!.view.frame
                self.progressIndicator?.center = CGPoint(x: parentFrame.width / 2.0, y: (parentFrame.height / 2.0) + 10)
                self.progressIndicator?.progress = 0.01

                if let completion = completion {
                    completion()
                }
            }
        } else {
            let indeterminantIndicator = AngularActivityIndicator(size: CGSize(width: indicatorSize, height: indicatorSize), lineWidth: 2.0, duration: 1.0)
            indeterminantIndicator.color = UIColor(red: 100 / 255, green: 100 / 255, blue: 100 / 255, alpha: 1.0)
            alertController!.view.addSubview(indeterminantIndicator)

            presentingController.present(alertController!, animated: true) { () in
                let parentFrame = self.alertController!.view.frame
                indeterminantIndicator.center = CGPoint(x: parentFrame.width / 2.0, y: (parentFrame.height / 2.0) + 10)
                indeterminantIndicator.startAnimating()

                if let completion = completion {
                    completion()
                }
            }
        }
    }

    func hideAlert(_ animated: Bool, completion: (() -> Void)? = nil) {
        alertController!.dismiss(animated: animated, completion: completion)
    }
}
