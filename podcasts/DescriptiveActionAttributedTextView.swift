import SwiftUI

struct DescriptiveActionAttributedTextView: View {
    @EnvironmentObject var theme: Theme
    @Environment(\.openURL) var openURL

    private let text: String
    private let onLinkTap: (() -> Void)?

    init(text: String, onLinkTap: (() -> Void)? = nil) {
        self.text = text
        self.onLinkTap = onLinkTap
    }

    var body: some View {
        Text(makeAttributedString())
            .multilineTextAlignment(.center)
            .foregroundColor(theme.primaryText01)
            .environment(\.openURL, OpenURLAction { url in
                onLinkTap?()
                open(url: url)
                return .handled
            })
    }

    private func makeAttributedString() -> AttributedString {
        var attributed = (try? AttributedString(markdown: text)) ?? AttributedString(text)
        attributed.font = .systemFont(ofSize: 15.0)
        for run in attributed.runs {
            if let _ = run.link {
                attributed[run.range].foregroundColor = theme.secondaryInteractive01
                attributed[run.range].underlineStyle = .none
            }
        }
        return attributed
    }

    private func open(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    DescriptiveActionAttributedTextView(
        text: "This download will use mobile data. You can turn off this warning in [Settings](pktc://settings/storage-and-data).",
        onLinkTap: {}
    )
        .environmentObject(Theme(previewTheme: .light))
}
