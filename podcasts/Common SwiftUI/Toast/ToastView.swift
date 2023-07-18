import SwiftUI

struct ToastView<Style: ToastTheme>: View {
    @ObservedObject var viewModel: ToastViewModel
    @ObservedObject var style: Style

    @State private var isVisible: Bool = false
    @State private var contentSize: CGSize = .zero
    @Environment(\.horizontalSizeClass) private var sizeClass

    // Dragging
    @GestureState private var dragPosition: Double = 0
    @State private var dismissDirection: DismissDirection = .none

    /// Fade the view out as we drag
    private var dragOpacity: Double {
        guard dismissDirection == .none else {
            return 0
        }

        return 1.0 - (abs(dragPosition) / contentSize.height).clamped(to: 0..<1)
    }

    /// Calculates the correct vertical offset
    private var dragOffset: Double {
        switch dismissDirection {
        case .none:
            return dragPosition
        case .down:
            return contentSize.height
        case .up:
            return -contentSize.height * 2
        }
    }

    var body: some View {
        wrapperView {
            toastWrapper {
                titleView

                Spacer(minLength: 10)

                ForEach(viewModel.actions) { action in
                    actionButton(action)
                }
            }
            .font(size: 14, style: .subheadline, weight: .medium)
        }
        // Wait for the initial content size to be calculated before appearing so we can animate in
        .onChange(of: contentSize, perform: { newValue in
            guard !isVisible else { return }

            isVisible = true
            viewModel.didAppear()
        })
        // Inform the view model that we're dismissing
        .onChange(of: dismissDirection) { newValue in
            guard newValue != .none else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                viewModel.didDismiss()
            }
        }
        // Handle when the view model tells us to auto dismiss
        .onChange(of: viewModel.didAutoDismiss) { newValue in
            guard newValue, dismissDirection == .none else { return }

            autoDismiss()
        }
    }

    // MARK: - Views

    private var titleView: some View {
        Text(viewModel.title)
            .padding(.vertical, ToastConstants.padding)
            .padding(.leading, ToastConstants.padding)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxHeight: .infinity)
            .foregroundStyle(style.title)
    }

    /// A full screen view that aligns the toast to the bottom
    private func wrapperView(_ content: @escaping () -> some View) -> some View {
        GeometryReader { proxy in
            // VStack over a ZStack since it correctly positions the toast view
            VStack(spacing: 0) {
                // Align the toast at the bottom
                Spacer()

                content()
                    // For larger devices restrict the toast width to a max of 50% of the view
                    .frame(width: sizeClass == .regular ? proxy.size.width * 0.5 : nil)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Wraps the content in a styled HStack and applies the animations
    private func toastWrapper(@ViewBuilder _ content: () -> some View) -> some View {
        HStack(spacing: 0) {
            content()
        }
        // Allow the child views to expand to the full height of the stack
        .fixedSize(horizontal: false, vertical: true)
        .background(style.background)
        .cornerRadius(ToastConstants.cornerRadius)
        .padding()
        .shadow(color: .black.opacity(0.3), radius: 10)

        // Animates the toast in from the bottom of the screen
        .offset(y: isVisible ? 0 : contentSize.height)
        .opacity(isVisible ? 1 : 0)
        .animation(ToastConstants.animation, value: isVisible)

        // Calculate the view size and inform the view model
        .background(GeometryReader(content: { proxy in
            Color.clear.onAppear {
                contentSize = proxy.size
                viewModel.updateFrame(proxy.frame(in: .global))
            }
        }))

        // Allow the view to be dragged to dismiss
        .offset(y: dragOffset)
        .opacity(dragOpacity)
        .animation(ToastConstants.animation, value: dragPosition)
        .gesture(dismissGesture)
    }

    /// Allow the view to be dragged to dismiss
    private var dismissGesture: some Gesture {
        DragGesture()
            .updating($dragPosition, body: { value, state, _ in
                state = value.translation.height
            })
            .onEnded { value in
                let translation = value.predictedEndTranslation.height
                let dragPercent = abs(translation) / contentSize.height

                guard dragPercent >= ToastConstants.dismissPercent else {
                    return
                }

                viewModel.willDismiss()
                dismissDirection = translation > 0 ? .down : .up
            }
    }

    // MARK: - Private: Helpers

    /// Creates a button for the given action
    private func actionButton(_ action: Toast.Action) -> some View {
        Text(action.title).buttonize {
            action.action()

            // Dismiss the toast by default when the action is triggered
            autoDismiss()
        } customize: { config in
            config.label
                .contentShape(Rectangle())
                .padding(.horizontal, ToastConstants.padding)
                .foregroundStyle(style.button)
                .frame(maxHeight: .infinity)
                .applyButtonEffect(isPressed: config.isPressed)
        }
    }

    /// Hide the view automatically
    private func autoDismiss() {
        viewModel.willDismiss()

        withAnimation {
            dismissDirection = .down
        }
    }
}

private enum DismissDirection {
    case none, down, up
}

private enum ToastConstants {
    static let cornerRadius = 4.0
    static let padding = 16.0
    static let dismissPercent = 0.3
    static let animation: Animation = .interpolatingSpring(stiffness: 350, damping: 50, initialVelocity: 10)
}

// MARK: - Previews

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ToastView(viewModel: .init(coordinator: PreviewCoordinator(), title: "Hello World", actions: [
            .init(title: "Tap Me", action: {
                print("Tapped")
            })], dismissTime: .infinity), style: .defaultTheme)
    }

    private struct PreviewCoordinator: ToastCoordinator {
        func toastDismissed() {
            print("Dismissed")
        }
    }
}
