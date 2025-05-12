import SwiftUI

protocol EmptyStateViewStyle: ObservableObject {
    var title: Color { get }
    var message: Color { get }
    var button: Color { get }
    var icon: Color { get }
}

/// Displays an informative view when there are no items to display and can be customized to show a custom view instead
/// of a text title.
///
/// The colors can be customized using EmptyStateViewStyle
struct EmptyStateView<Title: View, Style: EmptyStateViewStyle>: View {
    @ObservedObject var style: Style
    let icon: (() -> Image)?
    let title: () -> Title
    let message: String?
    let actions: [EmptyStateAction]

    init(
        @ViewBuilder title: @escaping () -> Title,
        message: String?,
        icon: (() -> Image)? = nil,
        actions: [EmptyStateAction],
        style: Style
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actions = actions
        self.style = style
    }

    var body: some View {
        VStack(spacing: EmptyConstants.spacing) {

            if let icon {
                icon()
                    .resizable()
                    .foregroundStyle(style.icon)
                    .frame(width: 30, height: 30)
            }

            title()
                .font(style: .subheadline, weight: .semibold)
                .foregroundStyle(style.title)

            if let message {
                Text(message)
                    .multilineTextAlignment(.center)
                    .font(style: .body)
                    .foregroundStyle(style.message)
            }

            HStack {
                ForEach(actions) { action in
                    Button(action.title) {
                        action.action()
                    }.buttonStyle(RoundedButtonStyle(theme: .sharedTheme))
                }
            }
            .font(style: .subheadline, weight: .medium)
            .foregroundStyle(style.button)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, EmptyConstants.padding)
        .padding(.vertical, EmptyConstants.verticalPadding)
        .padding(EmptyConstants.padding)
    }
}

struct EmptyStateAction: Identifiable {
    let title: String
    let action: () -> Void

    var id: String { title }
}

private enum EmptyConstants {
    static let cornerRadius = 4.0
    static let padding = 16.0
    static let verticalPadding = 24.0
    static let spacing = 12.0
}

extension EmptyStateView where Title == Text {
    init(title: String, message: String?, icon: (() -> Image)? = nil, actions: [EmptyStateAction], style: Style) {
        self.message = message
        self.actions = actions
        self.title = {
            Text(title)
        }
        self.style = style
        self.icon = icon
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView(title: "Hello World", message: "Hello how are you?", actions: [
            .init(title: "Empty Action", action: {
                print("Action!")
            })
        ], style: PreviewStyle())
    }

    private class PreviewStyle: EmptyStateViewStyle {
        var background: Color { .black }
        var title: Color { .white }
        var message: Color { .white.opacity(0.8) }
        var button: Color { .red }
        var icon: Color { .primary }
    }
}
