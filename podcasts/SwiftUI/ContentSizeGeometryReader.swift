import SwiftUI

/// `ContentSizeGeometryReader` is a wrapper around a `GeometryReader` that adjusts itself to the size of its content,
/// rather than taking up all the available space by default.
///
/// Using .frame(maxWidth: .infinity) or .frame(maxHeight: .infinity) on the content view will expand the GeometryReader
/// in a specific direction.
///
/// Set the `contentSizeUpdated` property to be informed of changes to the content size.
///
struct ContentSizeGeometryReader<Content: View>: View {
    let content: (GeometryProxy) -> Content
    var contentSizeUpdated: ((CGSize) -> Void)? = nil

    @State private var contentSize: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            ContentSizeReader(contentSize: $contentSize) {
                content(proxy)
            }
        }
        .frame(maxWidth: contentSize != .zero ? contentSize.width : nil)
        .frame(maxHeight: contentSize != .zero ? contentSize.height : nil)
        .onChange(of: contentSize) { newValue in
            contentSizeUpdated?(newValue)
        }
    }
}

// MARK: - Previews

struct ContentHeightView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewContent()
    }

    struct PreviewContent: View {
        var body: some View {
            ZStack {
                GeometryReader { proxy in
                    VStack {
                        Text("The GeometryReader is bound to \(String(describing: proxy.size))")

                        Rectangle()
                            .frame(width: 200, height: 200)
                    }
                }
                .background(Color.red)

                ContentSizeGeometryReader { proxy in
                    VStack {
                        Text("The GeometryReader is bound to \(String(describing: proxy.size))")
                            .fixedSize(horizontal: false, vertical: true)
                        Rectangle()
                            .frame(width: 200, height: 200)
                    }

                }
                .background(Color.blue)
            }
        }
    }
}
