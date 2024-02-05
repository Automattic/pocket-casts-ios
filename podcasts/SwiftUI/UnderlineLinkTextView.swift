import SwiftUI
import SafariServices

struct UnderlineLinkTextView: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        // Extract links and add underline to all of them
        let links = text.matches(for: "(?:__|[*#])|\\[(.*?)\\]\\(.*?\\)")
        var reimainingText = text
        var textView = links.count > 0 ? Text("") : Text(text)
        for (key, link) in links.enumerated() {
            let explode = reimainingText.components(separatedBy: link)
            textView = textView + Text(.init(explode.first ?? "")) + Text(.init(link)).underline() + (key == links.count-1 ? Text(.init(explode[safe: 1] ?? "")) : Text(""))
            reimainingText = explode[safe: 1] ?? ""
        }

        // Open the link inside the app
        return textView.environment(\.openURL, OpenURLAction { url in
            let safariViewController = SFSafariViewController(with: url)
            safariViewController.modalPresentationStyle = .formSheet
            SceneHelper.rootViewController()?.present(safariViewController, animated: true, completion: nil)
            return .handled
        })
    }
}

private extension String {
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self,
                                        range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}

#Preview {
    VStack {
        UnderlineLinkTextView("Hello World!")
        UnderlineLinkTextView("Hel[lo, Wor](https://pocketcasts.com)ld!")
        UnderlineLinkTextView("[Hello](https://pocketcasts.com), World!")
        UnderlineLinkTextView("Hello, [World](https://pocketcasts.com)!")
        UnderlineLinkTextView("I have [multiple](https://pocketcasts.com) [links](https://pocketcasts.com)!")
        UnderlineLinkTextView("Look [how](https://pocketcasts.com) cool [I](https://pocketcasts.com) [am](https://pocketcasts.com)! :)")
    }
}
