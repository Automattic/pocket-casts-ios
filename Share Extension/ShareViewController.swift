import UIKit
import Social

class ShareViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)

        redirectToHostApp()
    }

    func redirectToHostApp() {
        let url = URL(string: "pktc://item?id=20036169")
        let selectorOpenURL = sel_registerName("openURL:")
        let context = NSExtensionContext()
        context.open(url! as URL, completionHandler: nil)

        var responder = self as UIResponder?

        while responder != nil {
            if responder?.responds(to: selectorOpenURL) == true {
                responder?.perform(selectorOpenURL, with: url)
            }
            responder = responder!.next
        }
    }

}
