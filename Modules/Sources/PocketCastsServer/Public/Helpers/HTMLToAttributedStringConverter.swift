import Foundation
import SwiftSoup

/// Converts podcast / episode description HTML into a *semantic* `NSAttributedString`:
/// inline emphasis is tagged with ``emphasisAttributeKey``, links with `.link`, and
/// block structure (paragraphs, line breaks, list markers) becomes plain text. The UI
/// layer applies fonts and colours, which keeps this converter UIKit-free and usable
/// across platforms.
///
/// Avoids `NSAttributedString(documentType: .html)`, whose WebKit-backed importer is
/// synchronous, main-thread-only, and hangs intermittently in production.
public enum HTMLToAttributedStringConverter {

    public struct Emphasis: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let bold = Emphasis(rawValue: 1 << 0)
        public static let italic = Emphasis(rawValue: 1 << 1)
    }

    /// Value is an `NSNumber` wrapping an ``Emphasis`` raw value. Deliberately not
    /// Apple's `InlinePresentationIntent`, which requires macOS 12 (this package
    /// targets 10.15).
    public static let emphasisAttributeKey = NSAttributedString.Key("PCEmphasis")

    public static func attributedString(from html: String) -> NSAttributedString {
        guard !html.isEmpty else { return NSAttributedString() }

        guard containsHTMLTags(html) else {
            return NSAttributedString(string: normalizedPlainText(html))
        }

        do {
            let document = try SwiftSoup.parse(html)
            let root = document.body() ?? document
            let builder = AttributedStringBuilder()
            try builder.append(node: root, context: InlineContext())
            let result = builder.finalized()
            return result.length > 0
                ? result
                : NSAttributedString(string: normalizedPlainText(plainText(from: html)))
        } catch {
            return NSAttributedString(string: normalizedPlainText(plainText(from: html)))
        }
    }

    public static func plainText(from html: String) -> String {
        (try? SwiftSoup.parse(html).text()) ?? html
    }

    private static func containsHTMLTags(_ string: String) -> Bool {
        string.range(of: "<[a-zA-Z/!][^>]*>", options: .regularExpression) != nil
    }

    private static func normalizedPlainText(_ text: String) -> String {
        text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct InlineContext {
    var emphasis: HTMLToAttributedStringConverter.Emphasis = []
    var link: URL?

    var attributes: [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]
        if !emphasis.isEmpty {
            attributes[HTMLToAttributedStringConverter.emphasisAttributeKey] = NSNumber(value: emphasis.rawValue)
        }
        if let link {
            attributes[.link] = link
        }
        return attributes
    }
}

private final class AttributedStringBuilder {
    private let output = NSMutableAttributedString()

    /// Active list ancestry, innermost last. Drives nested indentation and ordered numbering.
    private var listStack: [ListContext] = []

    private struct ListContext {
        let ordered: Bool
        var index: Int
    }

    func finalized() -> NSAttributedString {
        let fullRange = NSRange(location: 0, length: output.length)
        output.mutableString.replaceOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression, range: fullRange)
        trimWhitespaceAndNewlines()
        return NSAttributedString(attributedString: output)
    }

    func append(node: Node, context: InlineContext) throws {
        for child in node.getChildNodes() {
            try appendChild(child, context: context)
        }
    }

    private func appendChild(_ node: Node, context: InlineContext) throws {
        if let textNode = node as? TextNode {
            let collapsed = textNode.getWholeText()
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            if collapsed.trimmingCharacters(in: .whitespaces).isEmpty {
                if output.length > 0, !endsWithNewline, !endsWithSpace {
                    appendText(" ", context: InlineContext())
                }
                return
            }
            appendText(collapsed, context: context)
            return
        }

        guard let element = node as? Element else { return }

        let tag = element.tagName().lowercased()
        switch tag {
        case "br":
            appendText("\n", context: InlineContext())
        case "p", "div", "section", "article":
            if listStack.isEmpty {
                ensureBlockSeparation()
                try append(node: element, context: context)
                ensureBlockSeparation()
            } else {
                // Inside a list item, a block wrapper must not inject blank lines
                // or bump content off the marker line.
                ensureSpace()
                try append(node: element, context: context)
            }
        case "strong", "b":
            var context = context
            context.emphasis.insert(.bold)
            try append(node: element, context: context)
        case "em", "i":
            var context = context
            context.emphasis.insert(.italic)
            try append(node: element, context: context)
        case "a":
            var context = context
            if let href = try? element.attr("href").trimmingCharacters(in: .whitespaces),
               !href.isEmpty, let url = URL(string: href) {
                context.link = url
            }
            try append(node: element, context: context)
        case "ul", "ol":
            if listStack.isEmpty {
                ensureBlockSeparation()
            } else {
                ensureNewline()
            }
            listStack.append(ListContext(ordered: tag == "ol", index: 1))
            try append(node: element, context: context)
            listStack.removeLast()
            if listStack.isEmpty {
                ensureBlockSeparation()
            }
        case "li":
            ensureNewline()
            appendText(listItemPrefix(), context: context)
            try append(node: element, context: context)
            ensureNewline()
        case "h1", "h2", "h3", "h4", "h5", "h6":
            ensureBlockSeparation()
            var context = context
            context.emphasis.insert(.bold)
            try append(node: element, context: context)
            ensureBlockSeparation()
        case "blockquote":
            ensureBlockSeparation()
            try append(node: element, context: context)
            ensureBlockSeparation()
        default:
            try append(node: element, context: context)
        }
    }

    private func appendText(_ string: String, context: InlineContext) {
        output.append(NSAttributedString(string: string, attributes: context.attributes))
    }

    // O(1) trailing-character checks: `NSMutableAttributedString.string` copies the
    // whole backing store on each access, so reading it per node is O(n²) on large
    // show notes; `mutableString.character(at:)` is O(1).
    private func character(fromEnd offset: Int) -> unichar? {
        let index = output.length - 1 - offset
        guard index >= 0 else { return nil }
        return output.mutableString.character(at: index)
    }

    private var endsWithNewline: Bool { character(fromEnd: 0) == ASCII.newline }
    private var endsWithSpace: Bool { character(fromEnd: 0) == ASCII.space }

    private func ensureBlockSeparation() {
        guard output.length > 0 else { return }
        if character(fromEnd: 0) != ASCII.newline {
            appendText("\n\n", context: InlineContext())
        } else if character(fromEnd: 1) != ASCII.newline {
            appendText("\n", context: InlineContext())
        }
    }

    private func ensureNewline() {
        guard output.length > 0, !endsWithNewline else { return }
        appendText("\n", context: InlineContext())
    }

    private func ensureSpace() {
        guard output.length > 0, !endsWithNewline, !endsWithSpace else { return }
        appendText(" ", context: InlineContext())
    }

    private func listItemPrefix() -> String {
        let depth = max(0, listStack.count - 1)
        let indent = String(repeating: "  ", count: depth)
        guard !listStack.isEmpty, listStack[listStack.count - 1].ordered else {
            return indent + "- "
        }
        let number = listStack[listStack.count - 1].index
        listStack[listStack.count - 1].index += 1
        return indent + "\(number). "
    }

    private func trimWhitespaceAndNewlines() {
        var end = output.length
        while end > 0, ASCII.isWhitespace(output.mutableString.character(at: end - 1)) {
            end -= 1
        }
        if end < output.length {
            output.deleteCharacters(in: NSRange(location: end, length: output.length - end))
        }
        var start = 0
        while start < output.length, ASCII.isWhitespace(output.mutableString.character(at: start)) {
            start += 1
        }
        if start > 0 {
            output.deleteCharacters(in: NSRange(location: 0, length: start))
        }
    }
}

private enum ASCII {
    static let tab: unichar = 0x09
    static let newline: unichar = 0x0A
    static let carriageReturn: unichar = 0x0D
    static let space: unichar = 0x20

    static func isWhitespace(_ character: unichar) -> Bool {
        character == space || character == newline || character == tab || character == carriageReturn
    }
}
