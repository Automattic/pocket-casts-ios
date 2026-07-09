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

    private func intent(_ attributed: NSAttributedString, at location: Int) -> InlinePresentationIntent {
        guard location < attributed.length,
              let intent = attributed.attribute(.inlinePresentationIntent, at: location, effectiveRange: nil) as? InlinePresentationIntent else {
            return []
        }
        return intent
    }

    private func link(_ attributed: NSAttributedString, at location: Int) -> URL? {
        guard location < attributed.length else { return nil }
        return attributed.attribute(.link, at: location, effectiveRange: nil) as? URL
    }

    // MARK: - Plain text

    func testEmptyInput() {
        XCTAssertEqual(string(""), "")
    }

    func testWhitespaceOnlyInputIsEmpty() {
        XCTAssertEqual(string("  \n  \n"), "")
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

    func testPlainTextNormalizesWindowsLineEndings() {
        XCTAssertEqual(string("Line one\r\nLine two"), "Line one\nLine two")
    }

    func testPlainTextCollapsesExcessBlankLines() {
        XCTAssertEqual(string("One\n\n\n\nTwo"), "One\n\nTwo")
    }

    func testAngleBracketBeforeNonLetterStaysText() {
        // "<" followed by a non-letter can't open a tag, so this is still plain text.
        XCTAssertEqual(string("I <3 podcasts & jazz"), "I <3 podcasts & jazz")
    }

    func testEntitiesInTagFreeTextAreDecoded() {
        // Real-world feed description (TED Talks Daily): no HTML tags at all,
        // but apostrophes arrive as numeric character references.
        let html = "Raised listening to his dad&#39;s old records, Joey Alexander plays a brand of sharp, modern piano jazz that you likely wouldn&#39;t expect to hear from a pre-teenager."
        XCTAssertEqual(string(html), "Raised listening to his dad's old records, Joey Alexander plays a brand of sharp, modern piano jazz that you likely wouldn't expect to hear from a pre-teenager.")
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

    func testNumericEntitiesInsideTagsAreDecoded() {
        let html = "<p>Raised listening to his dad&#39;s old records &#8212; jazz you wouldn&#8217;t expect.</p>"
        XCTAssertEqual(string(html), "Raised listening to his dad's old records — jazz you wouldn’t expect.")
    }

    func testUnknownTagsAreStripped() {
        XCTAssertEqual(string("<span class=\"x\">Hello</span>"), "Hello")
    }

    func testImagesAreDropped() {
        XCTAssertEqual(string("<p>Before<img src=\"x.png\">After</p>"), "BeforeAfter")
    }

    func testCommentsAreDropped() {
        XCTAssertEqual(string("<p>Before<!-- hidden -->After</p>"), "BeforeAfter")
    }

    func testScriptAndStyleContentsAreDropped() {
        // Script/style bodies are DataNodes, not TextNodes, so their contents
        // must never leak into the rendered description.
        XCTAssertEqual(string("<p>Hello</p><script>alert(1)</script><style>p { color: red }</style>"), "Hello")
    }

    func testWhitespaceInsideParagraphCollapses() {
        // Inside markup, raw newlines follow HTML whitespace rules.
        XCTAssertEqual(string("<p>Line one\n   Line two</p>"), "Line one Line two")
    }

    func testWhitespaceBetweenInlineElementsIsKept() {
        XCTAssertEqual(string("<b>bold</b> <i>italic</i>"), "bold italic")
    }

    func testBlockquoteIsBlockSeparated() {
        XCTAssertEqual(string("Before<blockquote>Quote</blockquote>After"), "Before\n\nQuote\n\nAfter")
    }

    func testTrailingLineBreaksAreTrimmed() {
        XCTAssertEqual(string("<p>Hello</p><br><br>"), "Hello")
    }

    func testCDATAContentIsKept() {
        // A feed that leaks a literal CDATA wrapper must not lose its content.
        XCTAssertEqual(string("<![CDATA[Hello]]>"), "Hello")
    }

    // MARK: - Inline emphasis

    func testBold() {
        let result = attributed("<strong>Hello</strong>")
        XCTAssertEqual(result.string, "Hello")
        XCTAssertTrue(intent(result, at: 0).contains(.stronglyEmphasized))

        XCTAssertTrue(intent(attributed("<b>Hello</b>"), at: 0).contains(.stronglyEmphasized))
    }

    func testItalic() {
        XCTAssertTrue(intent(attributed("<em>Hello</em>"), at: 0).contains(.emphasized))
        XCTAssertTrue(intent(attributed("<i>Hello</i>"), at: 0).contains(.emphasized))
    }

    func testEmphasisAppliesOnlyToItsRun() {
        let result = attributed("a <b>b</b> c") // "a b c"
        XCTAssertEqual(result.string, "a b c")
        XCTAssertTrue(intent(result, at: 2).contains(.stronglyEmphasized))   // "b"
        XCTAssertFalse(intent(result, at: 0).contains(.stronglyEmphasized))  // "a"
    }

    func testHeadingsAreBold() {
        let result = attributed("<h3>Title</h3>")
        XCTAssertEqual(result.string, "Title")
        XCTAssertTrue(intent(result, at: 0).contains(.stronglyEmphasized))
    }

    func testMalformedHTMLDoesNotCrashAndStillFormats() {
        let result = attributed("<p>Unclosed <b>bold") // SwiftSoup normalises the DOM
        XCTAssertEqual(result.string, "Unclosed bold")
        XCTAssertTrue(intent(result, at: result.length - 1).contains(.stronglyEmphasized))
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
        let result = attributed(#"<b>see <a href="https://pca.st">link</a></b>"#) // "see link"
        XCTAssertEqual(result.string, "see link")
        XCTAssertTrue(intent(result, at: 4).contains(.stronglyEmphasized))   // "link"
        XCTAssertEqual(link(result, at: 4), URL(string: "https://pca.st"))
        XCTAssertNil(link(result, at: 0))                        // "see "
    }

    func testMailtoLinkIsAllowed() {
        let result = attributed(#"<a href="mailto:hi@pocketcasts.com">Email</a>"#)
        XCTAssertEqual(result.string, "Email")
        XCTAssertEqual(link(result, at: 0), URL(string: "mailto:hi@pocketcasts.com"))
    }

    func testJavascriptSchemeIsNotLinked() {
        let result = attributed(#"<a href="javascript:alert(1)">Tap</a>"#)
        XCTAssertEqual(result.string, "Tap") // text preserved, link dropped
        XCTAssertNil(link(result, at: 0))
    }

    func testRelativeURLIsNotLinked() {
        // Scheme-less hrefs can't be opened safely on their own, so they stay plain text.
        let result = attributed(#"<a href="/episodes/1">Episode</a>"#)
        XCTAssertEqual(result.string, "Episode")
        XCTAssertNil(link(result, at: 0))
    }

    func testDataSchemeIsNotLinked() {
        let result = attributed(#"<a href="data:text/plain;base64,SGVsbG8=">Tap</a>"#)
        XCTAssertEqual(result.string, "Tap")
        XCTAssertNil(link(result, at: 0))
    }

    func testSchemeCheckIsCaseInsensitive() {
        XCTAssertNil(link(attributed(#"<a href="JavaScript:alert(1)">Tap</a>"#), at: 0))
        XCTAssertEqual(link(attributed(#"<a href="HTTPS://pca.st">Tap</a>"#), at: 0), URL(string: "HTTPS://pca.st"))
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
