import UIKit

/// How transcript text reads, both as the captured passage on the edit form and as the
/// full transcript in the editor.
enum BookmarkTranscriptStyle {
    static let fontSize: Double = 16
    static let lineHeightMultiple: Double = 1.5

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
}
