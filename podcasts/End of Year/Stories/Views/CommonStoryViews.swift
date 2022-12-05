import SwiftUI

/// A label used in the end of year stories that provides consistent styling
struct StoryLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .lineSpacing(2.5)
            .multilineTextAlignment(.center)
    }
}
