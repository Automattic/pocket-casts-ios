import SwiftUI


/// A simple Horizontally scrolling view that restricts its height to its content size
/// Example:
/// HorizontalScrollView {
///     ForEach(models) {
///         ... Setup View ...
///     }
/// }
struct HorizontalScrollView<Content: View>: View {
    private var content: () -> Content

    public init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }

    @State private var contentSize: CGSize?

    var body: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                ContentSizeReader { contentSize in
                    HStack(alignment: .top, spacing: 0) {
                        content()
                    }

                    Action { self.contentSize = contentSize }
                }
            }
            .frame(maxWidth: contentSize?.width ?? .zero)
        }
    }
}

struct HorizontalScrollView_Example_Preview: PreviewProvider {
    static var previews: some View {
        ExampleView()
    }

    struct ExampleView: View {
        var body: some View {
            HorizontalScrollView {
                ForEach(0..<100) { index in
                    VStack {
                        Text("Hello \(index)")
                        Text("World")
                    }.frame(width: 150, height: 150)
                        .background(Color.blue)
                        .padding([.leading, .trailing], 15)
                }
            }.background(Color.red)
        }
    }
}
