import SwiftUI

/// Displays an overlay view that displays text and icon only buttons
///
struct ActionBarOverlayView<Content: View>: View {
    var visible: Bool
    var title: String? = nil
    let content: () -> Content
    var actions: [Action] = []

    private let style = Style()

    @ScaledMetricWithMaxSize(relativeTo: .body) private var imageSize = 24

    var body: some View {
        ZStack(alignment: .bottom) {
            content()

            if visible {
                HStack {
                    // Show the title if needed
                    title.map {
                        Text($0)
                            .font(style: .subheadline, weight: .medium)
                            // Disable the animation so it doesn't fade when changed
                            .animation(.none, value: $0)
                    }

                    Spacer()

                    ForEach(actions) { action in
                        if action.visible {
                            actionButton(action)
                        }
                    }
                }
                .foregroundStyle(style.foregroundColor)
                // Inner Padding
                .padding(.vertical, ActionBarConstants.barPaddingVertical)
                .padding(.horizontal, ActionBarConstants.barPaddingHorizontal)
                .applyMaterial(tint: style.backgroundTint)
                .cornerRadius(ActionBarConstants.radius)
                // Outer Padding
                .padding(.horizontal, ActionBarConstants.barPaddingHorizontal)
            }
        }
        .accessibilityTransition(.opacity)
        .animation(.linear(duration: 0.1), value: visible)
        .padding(.bottom)
    }

    func barStyle(backgroundTint: Color, buttonColor: Color, foregroundColor: Color) -> Self {
        style.backgroundTint = backgroundTint
        style.buttonColor = buttonColor
        style.foregroundColor = foregroundColor
        return self
    }

    private func actionButton(_ action: Action) -> some View {
        Button {
            action.action()
        } label: {
            Image(action.imageName)
                .renderingMode(.template)
                .resizable()
                .frame(width: imageSize, height: imageSize)
                .padding(.vertical, ActionBarConstants.buttonPaddingVertical)
                .padding(.horizontal, ActionBarConstants.buttonPaddingHorizontal)
                .background(style.buttonColor)
                .cornerRadius(.infinity)
        }
        .accessibilityLabel(action.title)
        .opacity(action.visible ? 1 : 0)
        .accessibilityAnimation(.linear(duration: 0.1), value: action.visible)
    }

    struct Action: Identifiable {
        let imageName: String
        let title: String
        let visible: Bool
        let action: () -> Void

        init(imageName: String, title: String, visible: Bool = true, action: @escaping () -> Void) {
            self.imageName = imageName
            self.title = title
            self.visible = visible
            self.action = action
        }

        var id: String { title }
    }

    private class Style {
        var backgroundTint: Color = .white
        var buttonColor: Color = .white
        var foregroundColor: Color = .black
    }
}

private enum ActionBarConstants {
    static let radius = 12.0
    static let barPaddingVertical = 12.0
    static let barPaddingHorizontal = 16.0
    static let buttonPaddingHorizontal = 12.0
    static let buttonPaddingVertical = 4.0
}

private extension View {
    func applyMaterial(tint: Color) -> some View {
        self
            .background(.ultraThinMaterial)
            .background(tint)
            .environment(\.colorScheme, .dark)
    }
}

/// - Tag: ActionBarOverlayViewPreview
struct ActionBarOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewView()
    }

    private struct PreviewView: View {
        @State var visible = true
        @State var showAction = true

        var body: some View {
            ActionBarOverlayView(visible: visible, title: "Hello World", content: {
                VStack(spacing: 20) {
                    Button("Toggle Action Bar") {
                        withAnimation {
                            visible.toggle()
                        }
                    }.buttonStyle(.bordered)

                    Button("Toggle Action Visible") {
                        withAnimation {
                            showAction.toggle()
                        }
                    }.buttonStyle(.bordered)

                    Spacer()
                }.frame(maxWidth: .infinity)

            }, actions: [
                .init(imageName: "shelf_archive", title: "Archive", action: {
                    print("one")
                }),
                .init(imageName: "shelf_delete", title: "Delete", visible: showAction, action: {
                    print("two")
                })
            ])
            .barStyle(backgroundTint: .secondary, buttonColor: .accentColor, foregroundColor: .primary)
            .background(Color.primary.ignoresSafeArea())
        }
    }
}
