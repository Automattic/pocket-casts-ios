import SwiftUI

/// Displays an overlay view that displays the ActionBarView at the bottom
///
struct ActionBarOverlayView<Content: View, Style: ActionBarStyle>: View {
    /// Whether the action bar should appear in the view or not
    var actionBarVisible: Bool

    /// The label that appears in the action bar, this can be omitted
    var title: String? = nil

    /// The ActionBarStyle to use
    let style: Style

    /// The view to display the action bar in, ideally this should be a full height view
    let content: () -> Content

    /// The actions to display in the action bar
    var actions: [ActionBarView<Style>.Action] = []

    // Extra bottom padding to align the bar with the container view's bottom
    @State private var extraBottomPadding: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            content()

            if actionBarVisible {
                ActionBarView(title: title, style: style, actions: actions)
                    .padding(.bottom)
            }
        }
        // Push the overlay down so its bottom aligns to the
        // PodcastViewController's bottom (above mini player if visible)
        .padding(.bottom, extraBottomPadding)
        .accessibilityTransition(.opacity)
        .animation(.linear(duration: 0.1), value: actionBarVisible)
        .ignoresSafeArea()
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: GlobalFramePreferenceKey.self, value: proxy.frame(in: .global))
            }
        )
        .onPreferenceChange(GlobalFramePreferenceKey.self) { rect in
            updateExtraPadding(using: rect)
        }
        // Keep in sync with mini player visibility changes
        .onReceive(NotificationCenter.default.publisher(for: Constants.Notifications.miniPlayerDidAppear)) { _ in
            updateExtraPadding(using: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: Constants.Notifications.miniPlayerDidDisappear)) { _ in
            updateExtraPadding(using: nil)
        }
    }
}

private extension ActionBarOverlayView {
    func updateExtraPadding(using rect: CGRect?) {
        guard actionBarVisible else {
            extraBottomPadding = 0
            return
        }

        // Determine the space between this view's bottom and the key window's bottom
        let window = SceneHelper.connectedScene()?.windows.first(where: { $0.isKeyWindow })
        let windowHeight = window?.bounds.height ?? UIScreen.main.bounds.height
        let bottomSafeArea = window?.safeAreaInsets.bottom ?? 0

        // Target baseline matches other footers: 16pt above final bottom, adjusted for mini player
        let targetBottomInset = bottomSafeArea + MiniPlayerInsets.baseline(padding: 16)

        let viewMaxY = rect?.maxY ?? 0
        let additional = max(0, windowHeight - viewMaxY - targetBottomInset)

        // Avoid tiny jitter from fractional values
        extraBottomPadding = additional > 0.5 ? additional : 0
    }
}

private struct GlobalFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - ActionBarStyle

/// Allows parent views to customize the colors of the action bar
protocol ActionBarStyle {
    var backgroundTint: Color { get }
    var buttonColor: Color { get }
    var titleColor: Color { get }
    var iconColor: Color { get }
}

// MARK: - ActionBarView

struct ActionBarView<Style: ActionBarStyle>: View {
    /// The label that appears in the action bar, this can be omitted
    var title: String? = nil

    /// The ActionBarStyle to use
    let style: Style

    /// The actions to display in the action bar, this can be omitted
    var actions: [Action] = []

    @ScaledMetricWithMaxSize(relativeTo: .body, maxSize: .xxLarge) private var imageSize = 24

    var body: some View {
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
        .foregroundStyle(style.titleColor)
        // Inner Padding
        .padding(.vertical, ActionBarConstants.barPaddingVertical)
        .padding(.horizontal, ActionBarConstants.barPaddingHorizontal)
        .applyMaterial(tint: style.backgroundTint)
        .cornerRadius(ActionBarConstants.radius)
        // Outer Padding
        .padding(.horizontal, ActionBarConstants.barPaddingHorizontal)
    }

    // MARK: - Action! 🎬
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

    // MARK: - Private

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
                .foregroundColor(style.iconColor)
        }
        .accessibilityLabel(action.title)
        .opacity(action.visible ? 1 : 0)
        .accessibilityAnimation(.linear(duration: 0.1), value: action.visible)
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
            ActionBarOverlayView(actionBarVisible: visible, title: "Hello World", style: PreviewStyle(), content: {
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
        }
    }

    private struct PreviewStyle: ActionBarStyle {
        var backgroundTint: Color { .secondary }
        var buttonColor: Color { .accentColor }
        var titleColor: Color { .primary }
        var iconColor: Color { .primary }
    }
}
