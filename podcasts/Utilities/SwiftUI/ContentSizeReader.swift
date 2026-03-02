import SwiftUI

/// Calculates the size of the containing view and returns it
/// This allows you to easily get the size of the view without needing all the boilerplate for `GeometryReader`
struct ContentSizeReader<Content: View>: View {
    private let content: () -> Content

    @Binding var contentSize: CGSize

    public init(contentSize: Binding<CGSize>, @ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
        _contentSize = contentSize
    }

    public var body: some View {
        content().background (
            GeometryReader { geometry in
                Action {
                    $contentSize.wrappedValue = geometry.size
                }
            }
        )
    }
}

struct ContentSizeReader_Example_Preview: PreviewProvider {
    static var previews: some View {
        ExampleView()
    }

    struct ExampleView: View {
        @State private var contentSize: CGSize = .zero

        var body: some View {
            VStack {
                ContentSizeReader(contentSize: $contentSize) {
                    VStack {
                        Text(String(describing: contentSize))
                    }.frame(maxWidth: 200, maxHeight: 200)
                }
            }.background(Color.gray)
        }
    }
}
