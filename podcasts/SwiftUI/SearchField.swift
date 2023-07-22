import SwiftUI

struct SearchField: View {
    @ObservedObject var theme: SearchTheme = .init()

    /// The search text binding
    @Binding var text: String

    var showsCancelButton: Bool = true

    /// The placeholder text to display when the field is empty
    var placeholder: String = L10n.search

    /// Keeps track of whether the search field has focus or not
    @FocusState private var isFocused: Bool

    /// Whether we should show the cancel button, we keep this separate to ensure animations
    @State private var isCancelVisible = false

    /// If the control is `.disable(true)` or not. We'll fade out the search and remove any focus
    @Environment(\.isEnabled) private var isEnabled

    /// The scaled icon size
    @ScaledMetricWithMaxSize(relativeTo: .subheadline, maxSize: .xxLarge) private var iconSize = 16.0

    var body: some View {
        // We use 2 stacks here to have the cancel button appear outside the background
        HStack {
            HStack(spacing: SearchFieldConstants.padding) {
                Image("custom_search")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(theme.placeholder)

                let prompt = Text(placeholder).foregroundColor(theme.placeholder)

                TextField(placeholder, text: $text, prompt: prompt)
                    .foregroundColor(theme.text)
                    .focused($isFocused)
                    .padding(.vertical, SearchFieldConstants.padding)

                if !text.isEmpty {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.placeholder)
                        .buttonize {
                            text = ""
                        }
                }
            }
            .padding(.horizontal, SearchFieldConstants.padding)
            .background(theme.background)
            .cornerRadius(SearchFieldConstants.cornerRadius)
            .font(size: 14, style: .subheadline, weight: .medium)

            // Show the cancel button
            if showsCancelButton && isCancelVisible {
                Button(L10n.cancel) {
                    withAnimation {
                        text = ""
                        isFocused = false
                    }
                }
                .font(size: 14, style: .subheadline)
                .foregroundStyle(theme.cancel)
                .transition(
                    .move(edge: .trailing)
                    .combined(with: .opacity)
                    .animation(.linear(duration: 0.1))
                )
            }
        }
        // Fade the view out a bit if it's disabled
        .opacity(isEnabled ? 1 : 0.8)

        // Animate the shows cancel button in or out
        .onChange(of: isFocused) { newValue in
            withAnimation {
                isCancelVisible = newValue
            }
        }
        // If the disabled state changes, then remove focus from the field
        .onChange(of: isEnabled) { newValue in
            guard newValue else { return }

            isFocused = false
        }
    }

    class SearchTheme: ThemeObserver {
        var background: Color {
            theme.primaryField01
        }

        var placeholder: Color {
            theme.primaryField03
        }

        var text: Color {
            theme.primaryText01
        }

        var cancel: Color {
            theme.primaryInteractive01
        }
    }
}

private enum SearchFieldConstants {
    static let padding = 8.0
    static let cornerRadius = 8.0
}
