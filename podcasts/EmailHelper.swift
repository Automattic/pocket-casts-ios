import MessageUI
import PocketCastsUtils
import UIKit
import UniformTypeIdentifiers

/// Opens an email to support with the device details and logs filled in, the same way Android does.
class EmailHelper: NSObject {
    /// Dismisses the mail composer. Held statically because callers don't keep the helper around.
    private static let mailComposeDelegate = MailComposeDelegate()

    /// Debug builds launched with `-SupportForceMailtoFallback YES` take the path for devices without Mail set up.
    private static var forceMailtoFallback: Bool {
        #if DEBUG
            UserDefaults.standard.bool(forKey: "SupportForceMailtoFallback")
        #else
            false
        #endif
    }

    func presentSupportDialog(_ source: UIViewController, type: SupportRequestType) {
        let config = SupportConfig(type: type)
        let loadingAlert = ShiftyLoadingAlert(title: L10n.supportPreparingEmail)

        Task { @MainActor in
            loadingAlert.showAlert(source, hasProgress: false) {
                Task { @MainActor in
                    if MFMailComposeViewController.canSendMail() && !Self.forceMailtoFallback {
                        let attachments = await config.attachments()
                        loadingAlert.hideAlert(false) {
                            Self.presentMailComposer(source, config: config, attachments: attachments)
                        }
                    } else {
                        // Without Mail set up, a mailto: link can't carry attachments, so upload the logs
                        // and link them in the body instead. Respect the user's choice to leave them out.
                        // Wait for the uploads before opening the email app, which sends this app to the background,
                        // and keep running if the user leaves while they're still in progress.
                        let optOut = UserDefaults.standard.debugOptedOut
                        let backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Support log upload")
                        let logReferences = optOut ? [] : await config.uploadedLogReferences()
                        UIApplication.shared.endBackgroundTask(backgroundTask)
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
        guard let url = config.mailtoURL(body: body) else {
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
