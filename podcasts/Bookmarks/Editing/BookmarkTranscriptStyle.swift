import UIKit

/// How transcript text reads, both as the captured passage on the edit form and as the
/// full transcript in the editor.
enum BookmarkTranscriptStyle {
    static let fontSize: Double = 16
    static let lineHeightMultiple: Double = 1.5

    /// The room between one paragraph and the next, on top of the line height
    static let paragraphSpacing: Double = 10

    /// New York, scaling with the body text style
    static var font: UIFont {
        serifFont(ofSize: CGFloat(fontSize), scalingWith: .body)
    }

    /// The speaker names that introduce a passage, set smaller but in the same family
    static var speakerFont: UIFont {
        serifFont(ofSize: 12, scalingWith: .footnote)
    }

    private static func serifFont(ofSize size: CGFloat, scalingWith style: UIFont.TextStyle) -> UIFont {
        let font = UIFont.font(ofSize: size, scalingWith: style)
        guard let serif = font.fontDescriptor.withDesign(.serif) else {
            return font
        }

        return UIFont(descriptor: serif, size: font.pointSize)
    }

    static var lineHeight: CGFloat {
        font.pointSize * CGFloat(lineHeightMultiple)
    }

    /// What SwiftUI has to add between lines to reach `lineHeight`, which it measures
    /// from the bottom of one line to the top of the next
    static var lineSpacing: CGFloat {
        max(0, lineHeight - font.lineHeight)
    }

    /// TextKit puts the room a taller line height buys entirely above the glyphs, leaving
    /// them at the bottom of their line, and of any selection drawn over it. Raising the
    /// baseline by half splits that room evenly.
    static var baselineOffset: CGFloat {
        lineSpacing / 2
    }

    /// The transcript's text restyled for reading in a text view: the serif body font on
    /// the style's line height, with the speaker names set smaller
    static func styledTranscript(_ attributedText: NSAttributedString, textColor: UIColor) -> NSAttributedString {
        let text = NSMutableAttributedString(attributedString: attributedText)
        let fullRange = NSRange(location: 0, length: text.length)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.paragraphSpacing = CGFloat(paragraphSpacing)
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .natural

        text.addAttributes([.paragraphStyle: paragraphStyle,
                            .font: font,
                            .baselineOffset: baselineOffset,
                            .foregroundColor: textColor],
                           range: fullRange)

        text.enumerateAttribute(.transcriptSpeaker, in: fullRange, options: [.longestEffectiveRangeNotRequired]) { value, range, _ in
            guard value != nil else { return }

            text.addAttribute(.font, value: speakerFont, range: range)
        }

        return text
    }
}
