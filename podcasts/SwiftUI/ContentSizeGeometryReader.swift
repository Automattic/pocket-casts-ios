import SwiftUI

/// A GeometryReader wrapper view that calculates the size of the content and adjusts the
///
///
/// The contentSizeUpdated to be informed of the new content size outside of SwiftUI
///
/// This can be used to dynamically change the height of a SwiftUI view that's being used in UIKit
/// or use a GeometryReader without it taking up all the available space
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
                        Text("The geometry read is bound to \(String(describing: proxy.size))")

                        Rectangle()
                            .frame(width: 200, height: 200)
                    }
                }
                .background(Color.red)

                ContentSizeGeometryReader { proxy in
                    VStack {
                        Text("The geometry read is bound to \(String(describing: proxy.size))")
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
