import SwiftUI

/// `ScrollView` wrapper that allows views to be notified when the content offset changes by using
/// `.onContentOffsetChange`
///
/// See the [Preview](x-source-tag://ScrollViewWithContentOffsetPreview) for example usage
///
struct ScrollViewWithContentOffset<Content: View>: View {
    let content: () -> Content

    typealias ContentOffsetHandler = (CGPoint) -> Void
    @Namespace private var coordinateSpace
    private let coordinator = Coordinator()

    var body: some View {
        ScrollView {
            content().background(offsetObserverView)
        }
        .coordinateSpace(name: coordinateSpace)
        .onPreferenceChange(ScrollOriginPreferenceKey.self) { origin in
            coordinator.contentOffsetHandler?(origin)
        }
    }

    /// Add a callback that is called when the content offset changes
    func onContentOffsetChange(_ action: @escaping ContentOffsetHandler) -> some View {
        coordinator.contentOffsetHandler = action
        return self
    }

    @ViewBuilder private var offsetObserverView: some View {
        GeometryReader(content: { proxy in
            Color.clear
                .preference(key: ScrollOriginPreferenceKey.self, value: proxy.frame(in: .named(coordinateSpace)).origin)
        })
    }

    private class Coordinator {
        var contentOffsetHandler: ContentOffsetHandler? = nil
    }
}

private struct ScrollOriginPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}

/// - Tag: ScrollViewWithContentOffsetPreview
struct ScrollViewWithContentOffset_Previews: PreviewProvider {
    static var previews: some View {
        PreviewView()
    }

    private struct PreviewView: View {
        @State private var contentOffset: CGPoint = .zero

        var body: some View {
            VStack {
                Text("Y: **\(contentOffset.y)**")
                    .monospacedDigit()

                ScrollViewWithContentOffset {
                    VStack {
                        ForEach(0..<100) { index in
                            Text("Row \(index)")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
                .onContentOffsetChange { offset in
                    contentOffset = offset
                }
            }
        }
    }
}
