import SwiftUI
import PocketCastsUtils

/// Allows applying to styles to subtext located within a string
struct HighlightedText: View {
    typealias HighlightStyleBlock = (HighlightTokenizer.Token) -> HighlightStyle?

    /// Internal configuration to allow the view to "configure itself" without
    /// needing to pass everything through the init
    @ObservedObject private var config = Configuration()

    private let text: String

    init(_ text: String) {
        self.text = text.preventWidows()
    }

    var body: some View {
        if #available(iOS 15, *), let attributedString {
            Text(attributedString)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        } else {
            Text(text)
        }
    }

    // MARK: - View Configuration

    /// Sets the font for the entire text
    func font(_ font: Font) -> Self {
        config.font = font
        return self
    }

    /// Adds a new highlight string
    func highlight(_ string: String?) -> Self {
        if let string, !string.isEmpty {
            config.highlights.append(string)
        }
        return self
    }

    /// Adds new highlight strings
    func highlight(_ strings: [String]?) -> Self {
        if let strings, !strings.isEmpty {
            config.highlights.append(contentsOf: strings)
        }
        return self
    }


    /// This is called when a highlight match is ready for styling
    /// By default this will return `HighlightStyleBlock.defaultStyle`
    func onHighlight(_ block: @escaping HighlightStyleBlock) -> Self {
        config.highlightBlock = block
        return self
    }

    // MARK: - Private

    @available(iOS 15, *)
    private var attributedString: AttributedString? {
        let highlights = config.highlights
        guard !highlights.isEmpty else { return nil }

        // Get all the highlight matches in the form of tokens
        let tokenizer = HighlightTokenizer(text: text, highlights: highlights)
        let tokens = tokenizer.tokenize()

        // Create the base attributed string to return
        var string = AttributedString()

        for token in tokens {
            // Configure the base text
            var substring = AttributedString(token.string)
            substring.font = config.font

            defer { string += substring }

            // Apply highlight style below...
            guard token.type == .highlight else { continue }

            // If there isn't a style block defined, then use the default style
            let styleBlock = config.highlightBlock ?? { token in
                .defaultStyle
            }

            // If the style block returns nil, then don't apply a style
            guard let style = styleBlock(token) else { continue }

            // Use the base font if only the weight is specified
            if style.font == nil, let weight = style.weight {
                substring.font = config.font.weight(weight)
            } else {
                substring.font = style.font
            }

            // Set the foreground and background
            substring.foregroundColor = style.color
            substring.backgroundColor = style.backgroundColor
        }

        return string
    }

    // MARK: - Internal configuration state
    private class Configuration: ObservableObject {
        @Published var highlights: [String] = []
        @Published var font: Font = .body
        @Published var highlightBlock: HighlightStyleBlock? = nil
    }

    /// Defines a style for a highlight
    struct HighlightStyle {
        let font: Font?
        let weight: Font.Weight?
        let color: Color?
        let backgroundColor: Color?

        init(font: Font? = nil, weight: Font.Weight? = nil, color: Color? = nil, backgroundColor: Color? = nil) {
            self.font = font
            self.weight = weight
            self.color = color
            self.backgroundColor = backgroundColor
        }

        static let defaultStyle: HighlightStyle = .init(weight: .bold)
    }
}

// MARK: - Tokenizer

/// Converts the given text and highlights into a tokenized array
struct HighlightTokenizer {
    let text: String
    let highlights: [String]

    func tokenize() -> [Token] {
        var result = text

        for highlight in highlights {
            // If there's at least 1 match of the highlight, then replace all instances with a token
            if result.range(of: highlight) != nil {
                result = result.replacingOccurrences(of: highlight, with: token(string: highlight))
            }

            // If highlight string is multiple words, then also replace the nbsp version of the string
            // this will make sure we highlight the last few words of a string
            let nbspHighlight = highlight.nonBreakingSpaces()

            if highlight.contains(" "), result.range(of: nbspHighlight) != nil {
                result = result.replacingOccurrences(of: nbspHighlight, with: token(string: nbspHighlight))
            }
        }

        // Split on the delimiter to get a list of the token'd strings
        let components = result.components(separatedBy: Constants.delimeter)

        var tokens: [Token] = []
        var counter: [String: Int] = [:]

        for component in components {
            if component.isEmpty { continue }

            var string = component
            var type = Token.TokenType.string
            let key = string.nonBreakingSpaces()

            // If the first character is our highlight indicator
            // then remove the indicator, mark it as a highlight, and keep a running tally
            if string.first == Constants.highlight {
                string = String(component.dropFirst())
                type = .highlight

                counter[key] = (counter[key] ?? -1) + 1
            }

            tokens.append(Token(string: string, type: type, matchNumber: counter[key] ?? 0))
        }

        // Update all the total match counts for the highlights
        for var token in tokens {
            let key = token.string.nonBreakingSpaces()
            token.matchCount = counter[key] ?? 0
        }

        return tokens
    }

    // Wrap the highlight with the delimeter to split the text
    // Append the highlight token character so we can easily process it below
    private func token(string: String) -> String {
        Constants.delimeter + (String(Constants.highlight) + string) + Constants.delimeter
    }

    struct Token {
        let string: String
        let type: TokenType

        /// If there are multiple matches, this indicate which order it appeared in the text
        let matchNumber: Int

        /// The total number of matches for this highlight
        var matchCount: Int = 0

        enum TokenType {
            case string, highlight
        }
    }

    private enum Constants {
        /// The token wrapping delimeter
        /// This is a group separator character to prevent clashing with the actual text
        static let delimeter = "\u{001D}"

        /// The highlight indicator
        /// This is a a substitute character to prevent clashing with the actual text
        static let highlight = Character("\u{001A}")
    }
}

// MARK: - Demo

struct HighlightedText_Previews: PreviewProvider {
    struct DemoView: View {
        @State var toggle = true

        var body: some View {
            List {
                HighlightedText("Hello this has no highlighting applied to it")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                HighlightedText("The word world will be bolded")
                    .highlight("world")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                HighlightedText("The highlighted words will now be in a different font and background color 😱!")
                    .highlight(["highlighted", "now", "font"])
                    .font(.body)
                    .onHighlight { token in
                            .init(font: .title3.italic().weight(.heavy),
                                  color: .purple,
                                  backgroundColor: .yellow.opacity(0.3))
                    }.fixedSize(horizontal: false, vertical: true)

                HighlightedText("Match all words! One! Two! One! Two!")
                    .highlight("One")
                    .font(.body)
                    .onHighlight { token in
                            .init(font: .title3.italic().weight(.heavy),
                                  color: .purple,
                                  backgroundColor: .yellow.opacity(0.3))
                    }.fixedSize(horizontal: false, vertical: true)

                let diffString = "Have different styles for each match WOW!"
                let highlights = diffString.components(separatedBy: .whitespaces)
                let rainbow: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

                HighlightedText(diffString)
                    .highlight(highlights)
                    .font(.body)
                    .onHighlight { token in
                        guard let index = highlights.firstIndex(of: token.string) else {
                            return nil
                        }

                        return .init(font: .body.bold(), color: rainbow[index])
                    }.fixedSize(horizontal: false, vertical: true)

                HighlightedText("Tap to toggle: Match \(toggle ? "first" : "last") occurence!\nWord Word Word Word")
                    .highlight("Word")
                    .font(.body)
                    .onHighlight { token in
                        if (toggle && token.matchNumber != 0) || (!toggle && token.matchNumber < token.matchCount) {
                            return nil
                        }

                        return .defaultStyle
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .onTapGesture {
                        toggle.toggle()
                    }

            }.listStyle(.plain)

        }
    }

    static var previews: some View {
        DemoView()
    }
}
