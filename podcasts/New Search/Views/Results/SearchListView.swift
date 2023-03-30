import SwiftUI

struct SearchListView<Content: View>: View {
    @EnvironmentObject var theme: Theme

    let content: () -> Content

    public init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            ThemedDivider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    content()
                }
            }
            .modifier(DismissKeyboardOnScroll())
        }
        .background(AppTheme.color(for: .primaryUi02, theme: theme))
        .applyDefaultThemeOptions()
    }
}
