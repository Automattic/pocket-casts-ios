import SwiftUI
import PocketCastsUtils

/// Allows applying to styles to subtext located within a string
struct HighlightedText: View {
    typealias HighlightStyleBlock = (Highlight) -> HighlightStyle?

    // Internal config
    private var highlights: [String] = []
    private var font: Font = .body
    private var highlightBlocks: [String: HighlightStyleBlock] = [:]
    private let text: String

    init(_ text: String) {
        self.text = text.preventWidows()
    }

    var body: some View {
        if let attributedString {
            Text(attributedString)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        } else {
            Text(text)
        }
    }

    // MARK: - View Configuration

    /// Sets the font for the entire text
    func font(_ font: Font) -> Self {
        var mutableSelf = self
        mutableSelf.font = font
        return mutableSelf
    }

    /// Adds a new highlight string
    func highlight(_ string: String?, _ highlightBlock: HighlightStyleBlock? = nil) -> Self {
        var mutableSelf = self
        if let string, !string.isEmpty {
            mutableSelf.highlights.append(string)
            mutableSelf.highlightBlocks[Self.key(string)] = highlightBlock
        }
        return mutableSelf
    }

    /// Adds new highlight strings
    func highlight(_ strings: [String]?, _ highlightBlock: HighlightStyleBlock? = nil) -> Self {
        var mutableSelf = self

        if let strings, !strings.isEmpty {
            mutableSelf.highlights.append(contentsOf: strings)

            for string in strings {
                mutableSelf.highlightBlocks[Self.key(string)] = highlightBlock
            }
        }

        return mutableSelf
    }

    // MARK: - Private

    private var attributedString: AttributedString? {
        guard !highlights.isEmpty else { return nil }

        guard let string = try? AttributedString(markdown: tokenize(), including: \.highlight) else {
            return nil
        }

        return highlight(string: string)
    }

    /// Adds custom formatting to the attributed string
    private func highlight(string: AttributedString) -> AttributedString {
        var attrString = string
        attrString.font = font

        var counter: [String: Int] = [:]

        for run in attrString.runs {
            guard run.highlight == true else { continue }
            let range = run.range

            let key = Self.key(String(attrString.characters[range]))

            let matchCount = (counter[key] ?? -1) + 1
            counter[key] = matchCount

            let block = highlightBlocks[key]

            // If there isn't a style block defined, then use the default style
            let styleBlock = block ?? { _ in
                .defaultStyle
            }

            // If the style block returns nil, then don't apply a style
            guard let style = styleBlock(.init(string: key, matchNumber: matchCount)) else { continue }

            // Apply the style
            if style.font == nil, let weight = style.weight {
                attrString[range].font = font.weight(weight)
            } else {
                attrString[range].font = style.font
            }

            attrString[range].foregroundColor = style.color
            attrString[range].backgroundColor = style.backgroundColor
        }

        return attrString
    }

    /// The key to use to identify a match
    private static func key(_ string: String) -> String {
        string.nonBreakingSpaces()
    }

    /// Format the text with markdown
    private func tokenize() -> String {
        var result = text

        // Use custom start and end delimeters to prevent replacing token text
        let startToken = "\u{001A}"
        let endToken = "\u{001D}"

        // Wrap the given string in a token
        let token: (String) -> String = {
            startToken + $0 + endToken
        }

        for highlight in highlights {
            // If we have at least 1 result then tokenize all of them
            if result.range(of: highlight) != nil {
                result = result.replacingOccurrences(of: highlight, with: token(highlight))
            }

            // If the highlight is multi word, also replace the nbsp version of the string
            if highlight.contains(" ") {
                let nbspHighlight = highlight.nonBreakingSpaces()

                if result.range(of: nbspHighlight) != nil {
                    result = result.replacingOccurrences(of: nbspHighlight, with: token(nbspHighlight))
                }
            }
        }

        // Replace the custom start/end delimiters with markdown format
        return result
            .replacingOccurrences(of: startToken, with: "^[")
            .replacingOccurrences(of: endToken, with: "](highlight: true)")

    }

    // MARK: - Public structs
    struct Highlight {
        let string: String
        let matchNumber: Int
    }

    /// Defines a style for a highlight
    struct HighlightStyle {
        static let defaultStyle: HighlightStyle = .init(weight: .bold)

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
    }
}

// MARK: - Custom Markdown Format Attributes
private enum HighlightAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    typealias Value = Bool
    static var name: String = "highlight"
}

private extension AttributeScopes {
    struct HighlightTextAttributes: AttributeScope {
        let highlight: HighlightAttribute
    }

    var highlight: HighlightTextAttributes.Type { HighlightTextAttributes.self }
}

private extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.HighlightTextAttributes, T>) -> T {
        self[T.self]
    }
}

// MARK: - Demo

struct HighlightedText_Previews: PreviewProvider {
    struct DemoView: View {
        @State var counter = 0

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
                    .highlight(["highlighted", "now", "font", "background color"]) { _ in
                            .init(font: .title3.italic().weight(.heavy),
                                  color: .purple,
                                  backgroundColor: .yellow.opacity(0.3))
                    }
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                HighlightedText("Match all occurrences! One! Two! One! Two!")
                    .highlight("One") { _ in
                            .init(color: .blue)
                    }
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                let diffString = "Have different styles for each match WOW!"
                let highlights = diffString.components(separatedBy: .whitespaces)
                let rainbow: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

                HighlightedText(diffString)
                    .highlight(highlights) { highlight in
                        guard let index = highlights.firstIndex(of: highlight.string) else {
                            return nil
                        }

                        return .init(font: .body.bold(), color: rainbow[index])
                    }
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                let lipsum = "Click Me to change the highlight"
                let lipsumHighlights = lipsum.components(separatedBy: .whitespaces)
                HighlightedText(lipsum)
                    .highlight(lipsumHighlights[counter]) { _ in
                        return .init(color: .white, backgroundColor: .blue)
                    }
                    .highlight(lipsumHighlights[lipsumHighlights.count - 1 - counter]) { _ in
                        return .init(color: .white, backgroundColor: .red)
                    }
                    .font(.body.leading(.loose))
                    .fixedSize(horizontal: false, vertical: true)
                    .onTapGesture {
                        withAnimation(.interpolatingSpring(stiffness: 350, damping: 50, initialVelocity: 10)) {
                            counter = (counter + 1) % lipsumHighlights.count
                            print(counter, lipsumHighlights.count - 1 - counter)
                        }
                    }
            }.listStyle(.plain)
        }
    }

    static var previews: some View {
        DemoView()
    }
}
