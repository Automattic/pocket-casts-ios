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
                    return
                }

                let fileManager = FileManager.default
                guard let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.au.com.shiftyjelly.pocketcasts") else {
                    return
                }

                let destURL = container.appendingPathComponent("opml.opml")

                do { try FileManager.default.copyItem(at: url, to: destURL) } catch { }

                self?.close()

                self?.redirectToHostApp(destURL.absoluteString)
            }
        }
    }

    func redirectToHostApp(_ url: String) {
        guard let url = URL(string: "pktc://import-opml/\(url)") else {
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
