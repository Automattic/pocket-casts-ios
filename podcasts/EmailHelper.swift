import MessageUI
import PocketCastsUtils
import UIKit
import UniformTypeIdentifiers

/// Opens an email to support with the device details and logs filled in, the same way Android does.
class EmailHelper: NSObject {
    /// Dismisses the mail composer. Held statically because callers don't keep the helper around.
    private static let mailComposeDelegate = MailComposeDelegate()

    func presentSupportDialog(_ source: UIViewController, type: SupportRequestType) {
        let config = SupportConfig(type: type)
        let loadingAlert = ShiftyLoadingAlert(title: L10n.supportPreparingEmail)

        Task { @MainActor in
            loadingAlert.showAlert(source, hasProgress: false) {
                Task { @MainActor in
                    if MFMailComposeViewController.canSendMail() {
                        let attachments = await config.attachments()
                        loadingAlert.hideAlert(false) {
                            Self.presentMailComposer(source, config: config, attachments: attachments)
                        }
                    } else {
                        // Without Mail set up, a mailto: link can't carry attachments, so upload the logs
                        // and name them in the body instead. Respect the user's choice to leave them out.
                        let optOut = UserDefaults.standard.debugOptedOut
                        let logReferences = optOut ? [] : await config.uploadedLogReferences()
                        loadingAlert.hideAlert(false) {
                            Self.openMailApp(source, config: config, body: config.body(optOut: optOut, logReferences: logReferences))
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private static func presentMailComposer(_ source: UIViewController, config: SupportConfig, attachments: [SupportConfig.Attachment]) {
        FileLog.shared.addMessage("EmailHelper: opening the mail composer with \(attachments.count) attachments")

        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = mailComposeDelegate
        mailVC.setToRecipients([config.recipient])
        mailVC.setSubject(config.subject)
        attachments.forEach { attachment in
            mailVC.addAttachmentData(attachment.data, mimeType: UTType.plainText.preferredMIMEType ?? "text/plain", fileName: attachment.fileName)
        }
        source.present(mailVC, animated: true)
    }

    @MainActor
    private static func openMailApp(_ source: UIViewController, config: SupportConfig, body: String) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = config.recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: config.subject),
            URLQueryItem(name: "body", value: body)
        ]

        guard let url = components.url else {
            showNoMailAppAlert(source, config: config)
            return
        }

        FileLog.shared.addMessage("EmailHelper: Mail isn't set up, opening the default email app")
        UIApplication.shared.open(url) { opened in
            guard !opened else { return }
            FileLog.shared.addMessage("EmailHelper: no email app could open the support email")
            showNoMailAppAlert(source, config: config)
        }
    }

    @MainActor
    private static func showNoMailAppAlert(_ source: UIViewController, config: SupportConfig) {
        let alert = UIAlertController(title: L10n.supportNoEmailAppTitle, message: L10n.supportNoEmailAppMessage(config.recipient), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.supportCopyEmailAddress, style: .default) { _ in
            UIPasteboard.general.string = config.recipient
        })
        alert.addAction(UIAlertAction(title: L10n.supportOK, style: .cancel))
        source.present(alert, animated: true)
    }
}

private class MailComposeDelegate: NSObject, MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        FileLog.shared.addMessage("EmailHelper: mail composer finished with result \(result.rawValue)\(error.map { ", error: \($0)" } ?? "")")
        controller.dismiss(animated: true)
    }
}
