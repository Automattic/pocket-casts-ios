import SwiftUI

/// A type used by ScrollableScrollView for scrolling to a particular position
struct Scrollable {
    let prefix: String
    let scrollProxy: ScrollViewProxy

    func scrollTo(_ id: String, anchor: UnitPoint? = nil) {
        scrollProxy.scrollTo("\(prefix)_\(id)", anchor: anchor)
    }
}

/// A ScrollView which can be zoomed and scrolled using the Scrollable type provided in the Content block
struct ScrollableScrollView<Content: View>: View {

    @Binding var scale: CGFloat
    var duration: TimeInterval
    let geometry: GeometryProxy

    @State private var lastScale: CGFloat?

    @ViewBuilder let content: (Scrollable) -> Content

    private let scrollIDPrefix = "tick"

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .leading) {
                    invisibleTickMarks(for: geometry)
                        .frame(width: geometry.size.width * scale)
                    content(Scrollable(prefix: scrollIDPrefix, scrollProxy: scrollProxy))
                }
            }
            .clipped()
        }
    }

    /// A series of invisible "tick marks" used to mark positions in the scrollable view
    /// - Parameter geometry: Geometry proxy
    /// - Returns: A view containing a series of invisible tick marks
    @ViewBuilder private func invisibleTickMarks(for geometry: GeometryProxy) -> some View {
        let totalSeconds = Int(duration)
        let width = ((geometry.size.width * scale) / CGFloat(totalSeconds) / 2)
        HStack(spacing: width) {
            ForEach(0...totalSeconds, id: \.self) { second in
                Color.clear
                    .frame(width: width, height: geometry.size.height)
                    .id("\(scrollIDPrefix)_\(second)")
            }
        }
    }
}
