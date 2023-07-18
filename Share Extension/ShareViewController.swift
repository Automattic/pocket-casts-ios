import UIKit
import UniformTypeIdentifiers
import Social

class ShareViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let content = extensionContext?.inputItems.first as? NSExtensionItem
        guard let attachment = content?.attachments?.first as? NSItemProvider else {
            close()
            return
        }

        if attachment.hasItemConformingToTypeIdentifier(UTType.data.identifier) {

            attachment.loadItem(forTypeIdentifier: UTType.data.identifier, options: nil) { [weak self] data, error in
                guard let url = data as? URL else {
                    self?.close()
                    return
                }

                guard let opmlData = try? Data(contentsOf: url) else {
                    self?.close()
                    return
                }

                self?.close()

                self?.redirectToHostApp(opmlData.base64EncodedString())
            }
        }
    }

    func redirectToHostApp(_ encodedOPML: String) {
        guard let url = URL(string: "pktc://import-opml/\(encodedOPML)") else {
            return
        }

        let selectorOpenURL = sel_registerName("openURL:")
        let context = NSExtensionContext()
        context.open(url as URL, completionHandler: nil)

        var responder = self as UIResponder?

        while responder != nil {
            if responder?.responds(to: selectorOpenURL) == true {
                responder?.perform(selectorOpenURL, with: url)
            }
            responder = responder?.next
        }
    }

    private func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

}
