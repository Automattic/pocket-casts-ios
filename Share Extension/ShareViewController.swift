import UIKit
import UniformTypeIdentifiers
import Social

class ShareViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Get the attachment
        let content = extensionContext?.inputItems.first as? NSExtensionItem
        guard let attachment = content?.attachments?.first as? NSItemProvider else {
            close()
            return
        }

        // We only accept OPML files, and they need to conform to data identifier
        // If we ever want to accept other files we need to change the Share Extension
        // Info.plist
        if attachment.hasItemConformingToTypeIdentifier(UTType.data.identifier) {

            // Request the OPML file URL
            attachment.loadItem(forTypeIdentifier: UTType.data.identifier, options: nil) { [weak self] data, error in
                guard let url = data as? URL else {
                    self?.close()
                    return
                }

                // Convert the file to Data
                guard let opmlData = try? Data(contentsOf: url) else {
                    self?.close()
                    return
                }

                self?.close()

                // Redirect to Pocket Casts sharing the OPML data encoded in Base64
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
