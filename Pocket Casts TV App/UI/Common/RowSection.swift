import SwiftUI

/// Single source of truth for the spacing between Home + Discover sections
/// and between a section's title and its content row.
enum RowSectionLayout {
    static let titleSpacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 64
}

struct RowSection<Content: View>: View {
    private let title: String
    private let focusSection: AnyHashable
    private let content: Content

    @Environment(FocusStore.self) var focusStore

    init(title: String, focusSection: AnyHashable, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
        self.focusSection = focusSection
    }

    private var isFocusedSection: Bool {
        focusStore.focusedID == focusSection
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RowSectionLayout.titleSpacing) {
            titleView
            content
        }
        .focusSection()
    }

    // Always reserve space for the larger (focused) title so the layout
    // doesn't jump when the title resizes on focus changes. A hidden copy at
    // the largest font sizes the slot; the visible title is overlaid and
    // bottom-aligned so its distance to the content below stays constant.
    private var titleView: some View {
        HStack {
            Text(title)
                .font(.title3)
                .hidden()
                .overlay(alignment: .bottomLeading) {
                    Text(title)
                        .font(isFocusedSection ? .title3 : .headline)
                        .foregroundStyle(Color.pcTextPrimary)
                }
            Spacer()
        }
    }
}
