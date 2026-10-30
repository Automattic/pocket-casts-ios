import MessageUI
import PocketCastsUtils
import SwiftUI
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
            showNoMailAppSheet(source, config: config, body: body)
            return
        }

        FileLog.shared.addMessage("EmailHelper: Mail isn't set up, opening the default email app")
        UIApplication.shared.open(url) { opened in
            guard !opened else { return }
            FileLog.shared.addMessage("EmailHelper: no email app could open the support email")
            showNoMailAppSheet(source, config: config, body: body)
        }
    }

    /// Offers to copy the address and the email, so the device details and log links can still reach support from any email app.
    /// A sheet rather than an alert, because an alert closes after the first copy and there are two things to copy.
    @MainActor
    private static func showNoMailAppSheet(_ source: UIViewController, config: SupportConfig, body: String) {
        let sheet = NoEmailAppSheet(address: config.recipient, email: config.copyableEmail(body: body)) {
            source.dismiss(animated: true)
        }
        let host = ThemedHostingController(rootView: sheet, background: \.primaryUi01)
        if let sheetController = host.sheetPresentationController {
            sheetController.detents = [.custom { _ in 400 }, .large()]
            sheetController.prefersGrabberVisible = true
        }
        source.present(host, animated: true)
    }
}

private struct NoEmailAppSheet: View {
    private enum Item {
        case address
        case email
    }

    @EnvironmentObject var theme: Theme

    let address: String
    let email: String
    let onDone: () -> Void

    @State private var copied: Set<Item> = []

    var body: some View {
        VStack(spacing: 12) {
            Text(L10n.supportNoEmailAppTitle)
                .font(.system(size: 23.0, weight: .bold))
                .foregroundColor(theme.primaryText01)
            Text(L10n.supportNoEmailAppMessage(address))
                .font(.system(size: 15.0))
                .multilineTextAlignment(.center)
                .foregroundColor(theme.primaryText02)
                .padding(.bottom, 12.0)
            copyButton(.address, title: L10n.supportCopyEmailAddress, copiedTitle: L10n.supportEmailAddressCopied, value: address)
            copyButton(.email, title: L10n.supportCopyEmail, copiedTitle: L10n.supportEmailCopied, value: email)
            Button(L10n.done, action: onDone)
                .buttonStyle(BasicButtonStyle(textColor: theme.primaryText01, backgroundColor: theme.primaryUi01, borderColor: theme.primaryUi05))
        }
        .padding(.horizontal, 20.0)
        .padding(.top, 32.0)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(theme.primaryUi01)
    }

    private func copyButton(_ item: Item, title: String, copiedTitle: String, value: String) -> some View {
        Button {
            UIPasteboard.general.string = value
            copied.insert(item)
            UIAccessibility.post(notification: .announcement, argument: copiedTitle)
        } label: {
            if copied.contains(item) {
                Label(copiedTitle, systemImage: "checkmark")
            } else {
                Text(title)
            }
        }
        .buttonStyle(BasicButtonStyle(textColor: theme.primaryInteractive02, backgroundColor: theme.primaryInteractive01))
    }
}

private class MailComposeDelegate: NSObject, MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        FileLog.shared.addMessage("EmailHelper: mail composer finished with result \(result.rawValue)\(error.map { ", error: \($0)" } ?? "")")
        controller.dismiss(animated: true)
    }
}
