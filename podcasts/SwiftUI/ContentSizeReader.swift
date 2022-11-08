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
