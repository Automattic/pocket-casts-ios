import SwiftUI

protocol EmptyStateViewStyle: ObservableObject {
    var title: Color { get }
    var message: Color { get }
    var icon: Color { get }
    var button: Color { get }
}

struct EmptyStateAction: Identifiable {
    let id: String
    let view: AnyView

    init<Style: ButtonStyle>(
        title: String,
        style: Style = RoundedButtonStyle(theme: .sharedTheme),
        action: @escaping () -> Void
    ) {
        self.id = title
        self.view = AnyView(
            Button(title) {
                action()
            }.buttonStyle(style)
        )
    }

    init<Content: View>(
        id: String,
        @ViewBuilder content: () -> Content
    ) {
        self.id = id
        self.view = AnyView(content())
    }
}

/// Displays an informative view when there are no items to display and can be customized to show a custom view instead
/// of a text title.
///
/// The colors can be customized using EmptyStateViewStyle
struct EmptyStateView<Title: View, Style: EmptyStateViewStyle>: View {
    @ScaledMetric(relativeTo: .headline)
   private var iconSize = 30

    @ObservedObject var style: Style
    let icon: (() -> Image)?
    let title: () -> Title
    let message: String?
    let actions: [EmptyStateAction]
    let maxContentWidth: CGFloat?

    init(
        @ViewBuilder title: @escaping () -> Title,
        message: String?,
        icon: (() -> Image)? = nil,
        actions: [EmptyStateAction],
        style: Style,
        maxContentWidth: CGFloat? = 400
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actions = actions
        self.style = style
        self.maxContentWidth = maxContentWidth
    }

    var body: some View {
        VStack(spacing: EmptyConstants.spacing) {

            if let icon {
                icon()
                    .resizable()
                    .foregroundStyle(style.icon)
                    .frame(width: iconSize, height: iconSize)
            }

            title()
                .font(.headline)
                .foregroundStyle(style.title)

            if let message {
                Text(message)
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundStyle(style.message)
            }

            VStack {
                ForEach(actions) { action in
                    action.view
                }
            }
            .font(style: .subheadline, weight: .medium)
            .foregroundStyle(style.button)
        }
        .frame(maxWidth: maxContentWidth)
        .padding(.horizontal, EmptyConstants.padding)
        .padding(.vertical, EmptyConstants.verticalPadding)
        .padding(EmptyConstants.padding)
    }
}

private enum EmptyConstants {
    static let cornerRadius = 4.0
    static let padding = 16.0
    static let verticalPadding = 24.0
    static let spacing = 12.0
}

extension EmptyStateView where Title == Text {
    init(title: String,
         message: String?,
         icon: (() -> Image)? = nil,
         actions: [EmptyStateAction] = [],
         style: Style = .defaultStyle,
         maxContentWidth: CGFloat? = 400) {
        self.message = message
        self.actions = actions
        self.icon = icon
        self.title = {
            Text(title)
        }
        self.style = style
        self.maxContentWidth = maxContentWidth
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
        var title: Color { .white }
        var message: Color { .white.opacity(0.8) }
        var icon: Color { .primary }
        var button: Color { .red }
    }
}
