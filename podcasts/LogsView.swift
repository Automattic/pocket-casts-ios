import Foundation
import SwiftUI
import PocketCastsUtils
import MessageUI
import UniformTypeIdentifiers

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

    var shareURL: URL? {
        guard let data = logs.data(using: .utf8) else { return nil }
        let date = Date()
        let components = Calendar.current.dateComponents(in: .current, from: date)

        let dateString = String(format: "%04d-%02d-%02d-%02d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
            components.hour ?? 0,
            components.minute ?? 0,
            components.second ?? 0
        )
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("pocketcasts-logs-\(dateString).txt")
        try? data.write(to: tempURL)
        return tempURL
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
            NonEditableTextView(text: model.logs, scrolledToBottom: true)
            Spacer()
        }
        .navigationTitle(L10n.logs)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if MFMailComposeViewController.canSendMail() {
                    Button(action: {
                        model.mailLogs()
                    }, label: {
                        Image(systemName: "envelope")
                            .bold()
                    })
                }
                if let url = model.shareURL {
                    ShareLink(item: url, preview: SharePreview("logs.txt")) {
                        Image(systemName: "square.and.arrow.up")
                            .bold()
                    }
                }
            }
        }
        .foregroundStyle(theme.primaryIcon01)
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
