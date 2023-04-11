import SwiftUI

/// A horizontal carousel view with next item "peeking" support
/// - `carouselItemsToDisplay` to change how many of the `items` will be displayed per page
/// - `carouselItemSpacing` to adjust the spacing between the items
/// - `carouselPeekAmount` to control how much (if any) of the next item on the next page should display
/// - `carouselSwipeAnimation` to change the swipe/page change animation
/// Add the `currentIndex` binding to be notified when the page changes
struct HorizontalCarousel<Content: View, T: Identifiable>: View {
    /// Binding for the currently selected index
    @Binding private var index: Int

    /* Internal properties */
    private var itemsToDisplay = 1
    private var spacing: Double = 0
    private var peekAmount: PeekAmount = .constant(10)
    private var swipeAnimation: Animation = .interpolatingSpring(stiffness: 350, damping: 30)

    private let items: [T]
    private let content: (T) -> Content

    /// An offset amount set by the gesture used to move the items in the stack during a drag
    @GestureState private var gestureOffset: Double = 0

    /// Internal tracking of the visible index used to calculate the offset
    @State private var visibleIndex = 0

    init(currentIndex: Binding<Int>? = .constant(0), items: [T], @ViewBuilder content: @escaping (T) -> Content) {
        self._index = currentIndex ?? .constant(0)
        self.items = items
        self.content = content
    }

    /// Sets the number of items to display per page
    func carouselItemsToDisplay(_ value: Int) -> Self {
        update { carousel in
            carousel.itemsToDisplay = value.clamped(to: 0..<items.count)
        }
    }

    /// Sets the spacing between each item and the leading/trailing margins
    func carouselItemSpacing(_ value: CGFloat) -> Self {
        update { carousel in
            carousel.spacing = max(0, value)
        }
    }

    /// The amount the next item to display
    func carouselPeekAmount(_ value: PeekAmount) -> Self {
        update { carousel in
            carousel.peekAmount = value
        }
    }

    /// Update the animation that occurs when swiping between pages
    func carouselSwipeAnimation(_ value: Animation) -> Self {
        update { carousel in
            carousel.swipeAnimation = value
        }
    }

    /// The max total number of pages to be able to swipe through
    private var maxPages: Int {
        items.count - itemsToDisplay
    }

    var body: some View {
        GeometryReader { proxy in
            let baseWidth = proxy.size.width

            let peekAmount: Double = {
                switch self.peekAmount {
                case let .constant(value):
                    return value

                case let .percent(value):
                    return baseWidth * value
                }
            }()

            // Calculate the item size to be the width minus the trailing spacing and the trailing peek amount
            let itemWidth = (baseWidth - peekAmount) / CGFloat(itemsToDisplay)

            // The current X offset to apply to the HStack
            // This is what gives the appearance of scrolling since it pairs with the drag gesture offset
            // This uses negative values because we're moving the base X position to the left
            let offsetX: CGFloat = {
                let isLast = visibleIndex == maxPages

                // Add the leading padding and calculate the current item offset
                var x = (CGFloat(visibleIndex) * -itemWidth)

                // If we're displaying the last item, then adjust the offset so we show the peek on the leading side
                if isLast {
                    x += peekAmount
                }

                // Apply the gesture offset so the view updates
                x += gestureOffset

                return x
            }()

            let visibleFrame = proxy.frame(in: .global)

            // The actual carousel
            HStack(spacing: spacing) {
                ForEach(items) { item in
                    // Lazy load the content to improve performance
                    LazyLoadingView(visibleFrame: visibleFrame) {
                        content(item)
                    }
                    // Update each items width according to the calculated width above
                    .frame(width: max(0, itemWidth - spacing))
                }
            }
            .frame(minWidth: proxy.size.width, alignment: .leading)

            // Animate the swiping / page changes
            .animation(swipeAnimation, value: gestureOffset)
            .animation(swipeAnimation, value: visibleIndex)

            .offset(x: dampenOffset(offsetX))

            // Use a highPriorityGesture to give this priority when enclosed in another view with gestures
            .highPriorityGesture(
                DragGesture()
                    .onEnded { value in
                        // When the gesture is done, we use the predictedEnd calculate the next page based on the
                        // gestures momentum
                        let endIndex = calculateIndex(value.predictedEndTranslation, itemWidth: itemWidth)

                        // We're done animating so snap to the next index
                        visibleIndex = endIndex
                        index = endIndex
                    }
                    .onChanged { value in
                        // Inform the listening of index changes while we're dragging
                        index = calculateIndex(value.translation, itemWidth: itemWidth)
                    }
                    .updating($gestureOffset, body: { value, state, _ in
                        // Keep track of the gesture's offset so we can "scroll"
                        state = value.translation.width
                    })
            )
        }
    }

    /// Calculate the current index based on the given translation and item widths
    private func calculateIndex(_ translation: CGSize, itemWidth: CGFloat) -> Int {
        let offset = (-translation.width / itemWidth).rounded()

        return (visibleIndex + Int(offset))
            // Keep the next page within the page bounds
            .clamped(to: 0..<maxPages)
            // Prevent the next page from being more than page item away
            .clamped(to: visibleIndex-itemsToDisplay..<visibleIndex+itemsToDisplay)
    }

    /// Dampens the offset for the first and last pages
    private func dampenOffset(_ offset: Double) -> Double {
        guard visibleIndex == 0 || visibleIndex == maxPages else {
            return offset
        }

        // Scale the gesture offset down for the first and last items
        let adjustedOffset = offset - (gestureOffset * 0.7)

        return visibleIndex == 0 ? min(offset, adjustedOffset) : max(offset, adjustedOffset)
    }

    /// Passes a mutable version of self to the block and returns the modified version
    private func update(_ block: (inout Self) -> Void) -> Self {
        var mutableSelf = self
        block(&mutableSelf)
        return mutableSelf
    }

    enum PeekAmount {
        /// A static peek value
        case constant(Double)

        /// A dynamic value based off the total carousel width
        /// A value between 0 and 1
        /// Ex: 0.1 will have the peek take up 10% of the total carousel width
        case percent(Double)
    }
}

/// Uses a lightweight view to calcuate the size and origin of the expected view
/// and once it overlaps with the visible frame we load the content
///
/// This allows the carousel to lazily load the content but without using a LazyHStack which causes problems
/// with the gesture animations
///
private struct LazyLoadingView<Content: View>: View {
    let visibleFrame: CGRect
    let content: () -> Content

    @State private var isVisible = false

    var body: some View {
        if isVisible {
            content()
        } else {
            visibilityChecker
        }
    }

    private var visibilityChecker: some View {
        Color.clear
            .background (
                GeometryReader { proxy in
                    Action {
                        var frame = visibleFrame

                        // Expand the visible frame by 2 to load items that are currently off screen but may appear next
                        frame.size.width *= 2

                        // Calculate if this view is visible or not
                        isVisible = frame.intersects(proxy.frame(in: .global))
                    }
                }
            )
    }
}

// MARK: - Preview

struct HorizontalCarousel_Preview: PreviewProvider {
    static var previews: some View {
        ContainerView()
    }

    private struct ColorItem: Identifiable {
        let color: Color
        var id: String {
            color.description
        }
    }

    struct ContainerView: View {
        @State var peek: CGFloat = 50
        @State var spacing: CGFloat = 20
        @State var items: CGFloat = 1
        @State var isConstant: Bool = true

        var body: some View {
            let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
            let pages: [ColorItem] = colors.map { ColorItem(color: $0) }

            VStack {
                Spacer()

                Text("🎠 HorizontalCarousel.swift")
                    .font(.title)
                    .fontWeight(.bold)
                VStack {
                    HStack {
                        Text("Peek Type")
                        Spacer()
                        Button("Constant Amount") {
                            isConstant = true
                            peek = 10
                        }
                        .padding(5)
                        .background((isConstant ? Color.blue : Color.clear).cornerRadius(10))
                        .foregroundColor(isConstant ? Color.white : nil)

                        Button("Percentage") {
                            isConstant = false
                            peek = 0.1
                        }
                        .padding(5)
                        .background((!isConstant ? Color.blue : Color.clear).cornerRadius(10))
                        .foregroundColor(!isConstant ? Color.white : nil)

                    }
                    HStack {
                        Text("Peek Amount")
                        if isConstant {
                            Slider(value: $peek, in: 0...200)
                        } else {
                            Slider(value: $peek, in: 0...0.5)
                        }
                        Text("\(peek)")
                    }

                    HStack {
                        Text("Item Spacing")
                        Slider(value: $spacing, in: 0...50)
                        Text("\(spacing)")
                    }

                    HStack {
                        Text("Items Per Page")
                        Slider(value: $items, in: 1...20)
                        Text("\(Int(items))")
                    }
                }.padding()

                HorizontalCarousel(items: pages) { item in
                    Rectangle()
                        .cornerRadius(5)
                        .foregroundColor(item.color)
                }
                .carouselItemsToDisplay(Int(items))
                .carouselItemSpacing(spacing)
                .carouselPeekAmount(
                    isConstant ? .constant(peek) : .percent(peek)
                )
                .frame(height: 200)
                .padding(.leading, 20)

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}
