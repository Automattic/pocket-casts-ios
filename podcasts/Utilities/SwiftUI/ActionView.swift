import SwiftUI


/// This is a helper view that allows you to run code inline of SwiftUI without needing to move logic into .onAppear
/// It works by creating a completely empty view, waiting for .onAppear, and then trigering the action. Once the action
/// has been triggered, the emptyview is replaced with a Group to prevent any possible layout issues
/// Example Usage:
///
/// ```
///  ZStack{
///     Action { print("debugging is cool 😎") }
///     VStack {
///         ... some views ...
///     }
///
///     ... some views ...
///
///     Action {
///         viewModel.loadContent()
///     }
/// }
/// ```
struct Action: View {
    init(_ action: @escaping () -> Void) {
        self.action = action
    }

    private let action: () -> Void

    var body: some View {
        DispatchQueue.main.async {
            self.action()
        }

        return NoView()
    }

    /// This is a "view" that has no frame, and appears very far off screen.
    /// This allows the onAppear to still be called, but doesn't allow it appear in view at all
    private struct NoView: View {
        var body: some View {
            Color.clear
                .frame(width: 0, height: 0)
                .accessibility(hidden: true)
                .allowsHitTesting(false)
                .position(CGPoint(x: .max, y: .max))
        }
    }
}

struct ActionView_Example_Preview: PreviewProvider {
    static var previews: some View {
        ExampleView()
    }

    struct ExampleView: View {
        @State private var text: String = "Waiting..."

        var body: some View {
            VStack {
                Text(text)

                Action {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        text = "🎉🎉 The Action has Ran 🎉🎉"
                    }
                }
            }
        }
    }
}
