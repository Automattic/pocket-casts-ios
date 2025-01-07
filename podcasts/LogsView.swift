import Foundation
import SwiftUI
import PocketCastsUtils
import MessageUI

class LogsViewModel: NSObject, ObservableObject, MFMailComposeViewControllerDelegate {
    @Published var logs = ""
    var presenter: UIViewController?

    init(presenter: UIViewController? = nil) {
        self.presenter = presenter
    }

    func load() async {
        let result = await FileLog.shared.logFileAsString()
        await MainActor.run {
            self.logs = result
        }
    }

    func mailLogs() {
        guard MFMailComposeViewController.canSendMail() else {
            Toast.show(L10n.logsNoEmailAccountConfigured)
            return
        }
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = self

        mailVC.setSubject("iOS Logs \(Settings.appVersion())")
        mailVC.setToRecipients(["support@pocketcasts.com"])
        mailVC.setMessageBody("Please find attached my logs", isHTML: false)
        if let data = logs.data(using: .utf8) {
            mailVC.addAttachmentData(data, mimeType: UTType.plainText.preferredMIMEType ?? "plain/text", fileName: "logs.txt")
        }
        presenter?.present(mailVC, animated: true)
    }

    func mailComposeController(_ controller: MFMailComposeViewController,
                                       didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        presenter?.dismiss(animated: true)
    }

}

struct LogsView: View {
    @StateObject var model: LogsViewModel

    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack {
            TextEditor(text: $model.logs)
            Spacer()
        }
        .navigationTitle(L10n.logs)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    model.mailLogs()
                }, label: {
                    Image("mail")
                })
            }
        })
        .applyDefaultThemeOptions()
        .ignoresSafeArea()
        .task {
            await model.load()
        }
    }
}

#Preview {
    LogsView(model: LogsViewModel())
    .setupDefaultEnvironment()
}
