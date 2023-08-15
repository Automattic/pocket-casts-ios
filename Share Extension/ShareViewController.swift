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

        // We accept 3 types of files: audio, movie and opml
        var identifier: String = ""
        if attachment.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
            identifier = UTType.audio.identifier
        } else if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            identifier = UTType.movie.identifier
        } else if attachment.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
            identifier = UTType.data.identifier
        }
        loadFile(from: attachment, identifier: identifier)
    }

    func redirectToHostApp(_ url: String) {
        guard let url = URL(string: "pktc://import-file/\(url)") else {
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

    private func loadFile(from attachment: NSItemProvider, identifier: String) {
        attachment.loadItem(forTypeIdentifier: identifier, options: nil) { [weak self] data, error in
            guard let url = data as? URL else {
                return
            }

            // Save the file to the shared group directory
            let fileManager = FileManager.default
            guard let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: SharedConstants.GroupUserDefaults.groupContainerId) else {
                return
            }

            let destURL: URL
            if identifier == UTType.data.identifier {
                destURL = container.appendingPathComponent("opml.opml")
            } else {
                destURL = container.appendingPathComponent(url.lastPathComponent)
            }

            do { try FileManager.default.copyItem(at: url, to: destURL) } catch { }

            self?.close()

            // Redirect to Pocket Casts to handle the file
            self?.redirectToHostApp(destURL.absoluteString)
        }
    }

    private func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
