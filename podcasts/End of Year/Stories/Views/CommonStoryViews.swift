import SwiftUI

/// A label used in the end of year stories that provides consistent styling
struct StoryLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
        // Prevent widows from appearing due to the extra space of the ellipsis characters
        // Replace them with the single character space equivalent
            .replacingOccurrences(of: "...", with: "…")

        // Don't allow the word Pocket Casts to be broken up by inserting a non-breaking space
            .replacingOccurrences(of: "Pocket Casts", with: "Pocket\u{00a0}Casts")
    }

    var body: some View {
        Text(text)
            .lineSpacing(2.5)
            .multilineTextAlignment(.center)
    }
}
