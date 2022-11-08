import SwiftUI

/// Calculates the size of the containing view and returns it
/// This allows you to get easily get the size of the view without needing all the boilerplate for `GeometryReader`
struct ContentSizeReader<Content: View>: View {
    private var content: (CGSize?) -> Content

    init(@ViewBuilder _ content: @escaping (CGSize?) -> Content) {
        self.content = content
    }

    @State private var size: CGSize?

    var body: some View {
        // If we've calculated the size, then just return it and the view
        if let size {
            content(size)
        } else {
            content(nil).background(
                // Grab the size of just the content
                GeometryReader { contentGeometry in
                    Action {
                        size = contentGeometry.size
                    }
                }
            )
        }
    }
}

struct ContentSizeReader_Example_Preview: PreviewProvider {
    static var previews: some View {
        ExampleView()
    }

    struct ExampleView: View {
        @State private var size: String = "Waiting.."

        var body: some View {
            VStack {
                ContentSizeReader { contentSize in
                    VStack {
                        Text(size)
                    }.frame(maxWidth: 200, maxHeight: 200)

                    Action {
                        if let contentSize {
                            size = "Height: \(contentSize.height), Width: \(contentSize.width)"
                        }
                    }
                }
            }.background(Color.gray)
        }
    }
}
