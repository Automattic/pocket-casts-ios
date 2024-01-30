import SwiftUI

/// `NonBlockingLongPressView` is a view wrapper that allows the view to be long pressed, tapped,
/// and be informed of pressed state changes without blocking the dragging gesture of a `ScrollView`.
///
/// See the [Preview](x-source-tag://NonBlockingLongPressViewPreview) for an example.
///
struct NonBlockingLongPressView<Content: View>: View {
    let content: () -> Content
    var onTapped: (() -> Void)?
    var onPressed: ((Bool) -> Void)?
    var onLongPressed: (() -> Void)?

    @State private var pressed = false

    var body: some View {
        content().buttonize({}, onPressed: { pressed in
            self.pressed = pressed
        })
        // The order of the gestures matters, if the tapGesture is removed or before the longPress gesture then the
        // ScrollView drag will stop working
        .simultaneousGesture(longPressGesture)
        .highPriorityGesture(tapGesture)
        .onChange(of: pressed) { newValue in
            onPressed?(newValue)
        }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture().onEnded { _ in
            onLongPressed?()
            pressed = false
        }
    }

    private var tapGesture: some Gesture {
        TapGesture().onEnded { _ in
            onTapped?()
            flashPressed()
        }
    }

    // onPressed isn't called when the tap gesture happens so we simulate the tap here by changing the value and reverting it
    private func flashPressed() {
        pressed = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.pressed = false
        }
    }
}

/// - Tag: NonBlockingLongPressViewPreview
struct NonBlockingLongPressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("The items in the left ScrollView use `onLongPressGesture` which blocks the scrolling.\n\nThe items in the right ScrollView use `NonBlockingLongPressView` which allows for scrolling + gestures.")

            HStack {
                ScrollView {
                    ForEach(0..<100) { index in
                        Text("Row \(index)")
                            .padding()
                            .background(Color.red)
                            .onLongPressGesture {
                                print("Long pressed!")
                            }
                    }
                }

                ScrollView {
                    ForEach(0..<100) { index in
                        NonBlockingLongPressView {
                            Text("Row \(index)")
                                .padding()
                                .background(Color.blue)

                        } onLongPressed: {
                            print("Long Pressed!")
                        }
                    }
                }
            }
        }.padding()
    }
}
