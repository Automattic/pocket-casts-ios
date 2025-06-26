import SwiftUI

struct DescriptiveActionAttributedTextView: View {
    @EnvironmentObject var theme: Theme
    @Environment(\.openURL) var openURL

    private let text: String
    private let attributes: [String: URL]
    private let onLinkTap: (() -> Void)?

    init(text: String, attributes: [String: URL], onLinkTap: (() -> Void)? = nil) {
        self.text = text
        self.attributes = attributes
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
        var attributed = AttributedString(text)
        attributed.font = .systemFont(ofSize: 15.0)
        attributes.forEach { key, value in
            if let range = attributed.range(of: key) {
                attributed[range].foregroundColor = theme.secondaryInteractive01
                attributed[range].link = value
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
        text: "This download will use mobile data. You can turn off this warning in Settings.",
        attributes: ["Settings": URL(string: "pktc://settings/storage-and-data")!],
        onLinkTap: {}
    )
        .environmentObject(Theme(previewTheme: .light))
}
