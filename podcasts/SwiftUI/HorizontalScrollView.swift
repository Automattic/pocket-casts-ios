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
                    Action { self.contentSize = contentSize }

                    HStack(alignment: .top, spacing: 0) {
                        content()
                    }
                }
            }
            .frame(maxWidth: contentSize?.width ?? .zero)
        }
    }
}
