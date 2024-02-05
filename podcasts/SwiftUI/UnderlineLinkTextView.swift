import SwiftUI

struct UnderlineLinkTextView: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        let links = matches(for: "(?:__|[*#])|\\[(.*?)\\]\\(.*?\\)", in: text)
        var reimainingText = text
        var textView = links.count > 0 ? Text("") : Text(text)
        for (key, link) in links.enumerated() {
            let explode = reimainingText.components(separatedBy: link)
            textView = textView + Text(.init(explode.first ?? "")) + Text(.init(link)).underline() + (key == links.count-1 ? Text(.init(explode[safe: 1] ?? "")) : Text(""))
            reimainingText = explode[safe: 1] ?? ""
        }
        return textView
    }

    func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
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
