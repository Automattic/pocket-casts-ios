import Foundation
import SwiftUI
import PocketCastsUtils
import UniformTypeIdentifiers

class LogsViewModel: NSObject, ObservableObject {
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
}

struct LogsView: View {
    @StateObject var model: LogsViewModel

    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack {
            TextEditor(text: $model.logs.readOnly)
            Spacer()
        }
        .navigationTitle(L10n.logs)
        .toolbar(content: {
            if let url = model.shareURL {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: url, preview: SharePreview("logs.txt")) {
                        Image(systemName: "square.and.arrow.up").bold()
                    }
                    .foregroundStyle(theme.primaryIcon01)
                }
            }
        })
        .applyDefaultThemeOptions()
        .ignoresSafeArea()
        .task {
            await model.load()
        }
    }
}

fileprivate extension Binding {
    var readOnly: Binding<Value> {
        Binding(get: { self.wrappedValue }, set: { _ in })
    }
}

#Preview {
    LogsView(model: LogsViewModel())
    .setupDefaultEnvironment()
}
