import SwiftUI

/// This will dynamically replace itself with a ScrollView if it detects that the containing content will overflow
/// outside of its original bounds
public struct ScrollViewIfNeeded<Content: View>: View {
    private var content: () -> Content

    public init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }

    @State private var willOverflow: Bool? = nil

    public var body: some View {
        // If the content size if going to overflow outside of the view bounds, then wrap the content in a scrollview
        if willOverflow == true {
            ScrollView { content() }
        }
        // If we don't need to wrap in a scroll view, then just return the original content
        else if willOverflow == false {
            content()
        }
        // If the content size hasn't been calculated yet, then do that..
        else {
            // Create an initial geometry reader to compare against
            GeometryReader { geometry in
                content().background(
                    // Calculate the content size again, but this time of the "true" size
                    GeometryReader { contentSize in
                        Action {
                            willOverflow = contentSize.size.height > geometry.size.height
                        }
                    }
                )
            }
        }
    }
}

struct ScrollViewIfNeeded_Example_Preview: PreviewProvider {
    static var previews: some View {
        ExampleView()
    }

    struct ExampleView: View {
        @State private var forceScroll: Bool = false

        var body: some View {
            VStack {
                ScrollViewIfNeeded {
                    VStack(alignment: .center) {
                        Text("Top Text")
                        Spacer()
                        Button(forceScroll ? "⬇️ Scroll Down ⬇️" : "Click to make the view scrollable") {
                            forceScroll.toggle()
                        }.buttonStyle(ScrollButtonStyle())
                        Spacer()
                        Text(forceScroll ? "👋 Hi." : "Bottom Text")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .frame(height: forceScroll ? 1000 : nil)
                }.id(forceScroll)
            }
        }
    }

    private struct ScrollButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .foregroundColor(.black)
                .contentShape(Rectangle())
        }
    }
}
