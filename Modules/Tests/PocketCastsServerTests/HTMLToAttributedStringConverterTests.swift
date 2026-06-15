import Foundation
@testable import PocketCastsServer
import XCTest

final class HTMLToAttributedStringConverterTests: XCTestCase {

    private func attributed(_ html: String) -> NSAttributedString {
        HTMLToAttributedStringConverter.attributedString(from: html)
    }

    private func string(_ html: String) -> String {
        attributed(html).string
    }

    private func emphasis(_ attributed: NSAttributedString, at location: Int) -> HTMLToAttributedStringConverter.Emphasis {
        guard location < attributed.length,
              let raw = (attributed.attribute(HTMLToAttributedStringConverter.emphasisAttributeKey, at: location, effectiveRange: nil) as? NSNumber)?.intValue else {
            return []
        }
        return HTMLToAttributedStringConverter.Emphasis(rawValue: raw)
    }

    private func link(_ attributed: NSAttributedString, at location: Int) -> URL? {
        guard location < attributed.length else { return nil }
        return attributed.attribute(.link, at: location, effectiveRange: nil) as? URL
    }

    // MARK: - Plain text

    func testEmptyInput() {
        XCTAssertEqual(string(""), "")
    }

    func testPlainTextPassthrough() {
        XCTAssertEqual(string("Just a description."), "Just a description.")
    }

    func testPlainTextIsNotEscaped() {
        // The whole point of going direct: no Markdown means no escaping.
        XCTAssertEqual(string("5 * 3 and a_b and [x]"), "5 * 3 and a_b and [x]")
    }

    func testPlainTextPreservesLineBreaks() {
        XCTAssertEqual(string("Line one\nLine two"), "Line one\nLine two")
    }

    // MARK: - Blocks

    func testParagraphsBecomeBlankLineSeparated() {
        XCTAssertEqual(string("<p>One</p><p>Two</p>"), "One\n\nTwo")
    }

    func testLineBreakBecomesNewline() {
        XCTAssertEqual(string("Line1<br>Line2"), "Line1\nLine2")
    }

    func testEntitiesAreDecoded() {
        XCTAssertEqual(string("<p>Tom &amp; Jerry</p>"), "Tom & Jerry")
    }

    func testUnknownTagsAreStripped() {
        XCTAssertEqual(string("<span class=\"x\">Hello</span>"), "Hello")
    }

    func testImagesAreDropped() {
        XCTAssertEqual(string("<p>Before<img src=\"x.png\">After</p>"), "BeforeAfter")
    }

    // MARK: - Inline emphasis

    func testBold() {
        let result = attributed("<strong>Hello</strong>")
        XCTAssertEqual(result.string, "Hello")
        XCTAssertTrue(emphasis(result, at: 0).contains(.bold))

        XCTAssertTrue(emphasis(attributed("<b>Hello</b>"), at: 0).contains(.bold))
    }

    func testItalic() {
        XCTAssertTrue(emphasis(attributed("<em>Hello</em>"), at: 0).contains(.italic))
        XCTAssertTrue(emphasis(attributed("<i>Hello</i>"), at: 0).contains(.italic))
    }

    func testEmphasisAppliesOnlyToItsRun() {
        let result = attributed("a <b>b</b> c") // "a b c"
        XCTAssertEqual(result.string, "a b c")
        XCTAssertTrue(emphasis(result, at: 2).contains(.bold))   // "b"
        XCTAssertFalse(emphasis(result, at: 0).contains(.bold))  // "a"
    }

    func testHeadingsAreBold() {
        let result = attributed("<h3>Title</h3>")
        XCTAssertEqual(result.string, "Title")
        XCTAssertTrue(emphasis(result, at: 0).contains(.bold))
    }

    func testMalformedHTMLDoesNotCrashAndStillFormats() {
        let result = attributed("<p>Unclosed <b>bold") // SwiftSoup normalises the DOM
        XCTAssertEqual(result.string, "Unclosed bold")
        XCTAssertTrue(emphasis(result, at: result.length - 1).contains(.bold))
    }

    // MARK: - Links

    func testLink() {
        let result = attributed(#"<a href="https://pocketcasts.com">Pocket Casts</a>"#)
        XCTAssertEqual(result.string, "Pocket Casts")
        XCTAssertEqual(link(result, at: 0), URL(string: "https://pocketcasts.com"))
    }

    func testLinkWithoutHrefIsPlainText() {
        let result = attributed("<a>Just text</a>")
        XCTAssertEqual(result.string, "Just text")
        XCTAssertNil(link(result, at: 0))
    }

    func testNestedInlineCarriesBothBoldAndLink() {
        let result = attributed(#"<b>see <a href="u">link</a></b>"#) // "see link"
        XCTAssertEqual(result.string, "see link")
        XCTAssertTrue(emphasis(result, at: 4).contains(.bold))   // "link"
        XCTAssertEqual(link(result, at: 4), URL(string: "u"))
        XCTAssertNil(link(result, at: 0))                        // "see "
    }

    // MARK: - Lists

    func testUnorderedList() {
        XCTAssertEqual(string("<ul><li>A</li><li>B</li></ul>"), "- A\n- B")
    }

    func testListIgnoresInterTagWhitespace() {
        XCTAssertEqual(string("<ul>\n  <li>A</li>\n  <li>B</li>\n</ul>"), "- A\n- B")
    }

    func testOrderedListNumbering() {
        XCTAssertEqual(string("<ol><li>First</li><li>Second</li></ol>"), "1. First\n2. Second")
    }

    func testNestedUnorderedList() {
        let html = "<ul><li>A<ul><li>A1</li><li>A2</li></ul></li><li>B</li></ul>"
        XCTAssertEqual(string(html), "- A\n  - A1\n  - A2\n- B")
    }

    func testDeeplyNestedList() {
        let html = "<ul><li>A<ul><li>B<ul><li>C</li></ul></li></ul></li></ul>"
        XCTAssertEqual(string(html), "- A\n  - B\n    - C")
    }

    func testNestedOrderedListNumberingIsPerList() {
        let html = "<ol><li>A<ol><li>x</li><li>y</li></ol></li><li>B</li></ol>"
        XCTAssertEqual(string(html), "1. A\n  1. x\n  2. y\n2. B")
    }

    func testListItemsWrappedInParagraphsStayTight() {
        // WordPress-style feeds wrap <li> content in <p>; this must not inject blank lines.
        let html = "<ul><li><p>A</p></li><li><p>B</p></li></ul>"
        XCTAssertEqual(string(html), "- A\n- B")
    }

    func testListItemWithTextAndParagraph() {
        XCTAssertEqual(string("<ul><li>text<p>more</p></li></ul>"), "- text more")
    }
}
