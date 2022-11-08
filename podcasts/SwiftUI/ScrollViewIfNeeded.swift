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
                    ContentSizeReader { contentSize in
                        Action {
                            guard let contentSize else { return }

                            willOverflow = contentSize.height > geometry.size.height
                        }
                    }
                )
            }
        }
    }
}
