import SwiftUI

/// A list view wrapper that can toggle a selection checkbox visible
///
/// See the [Preview](x-source-tag://MultiSelectRowPreview) for example usage
struct MultiSelectRow<Content: View>: View {
    /// Whether the row should display the select button in the row
    let showSelectButton: Bool

    /// Whether the select button should appear in its selected state
    let selected: Bool

    /// The row content to wrap
    let content: () -> Content

    /// Called when the selection toggle is tapped
    let onSelectionToggled: () -> Void

    @ScaledMetricWithMaxSize(relativeTo: .body, maxSize: .xxLarge) private var multiSelectButtonSize = 24
    @ScaledMetricWithMaxSize(relativeTo: .body, maxSize: .xxLarge) private var checkSize = 20

    private let style = Style()

    var body: some View {
        HStack(spacing: 15) {
            if showSelectButton {
                buttonView.buttonize {
                    onSelectionToggled()
                } customize: { config in
                    config.label.applyButtonEffect(isPressed: config.isPressed)
                }
                .accessibilityTransition(.move(edge: .leading).combined(with: .opacity))
            }

            content()
        }
    }

    /// Customizes the selection button colors
    func selectButtonStyle(tintColor: Color, checkColor: Color) -> Self {
        style.tint = tintColor
        style.check = checkColor
        return self
    }

    // MARK: - Private

    /// The unselected select button
    private var buttonView: some View {
        Circle()
            .stroke(lineWidth: 2)
            .fill(style.tint)
            .frame(width: multiSelectButtonSize, height: multiSelectButtonSize)
            .overlay(selectedView)
    }

    /// The selected button state
    private var selectedView: some View {
        ZStack {
            Circle().fill(style.tint)

            Image("discover_tick")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: checkSize)
                .foregroundStyle(style.check)
        }
        .opacity(selected ? 1 : 0)
        .animation(.linear(duration: 0.1), value: selected)
    }

    private class Style {
        var tint: Color = .white
        var check: Color = .black
    }
}

// MARK: - Previews

/// - Tag: MultiSelectRowPreview

struct MultiSelectRow_Previews: PreviewProvider {
    static var previews: some View {
        PreviewView()
    }

    private struct PreviewView: View {
        @State private var visible = false
        @State private var selected = false

        var body: some View {
            VStack(spacing: 20) {
                Button("Toggle Visible") {
                    withAnimation {
                        visible.toggle()
                    }
                }.buttonStyle(.borderedProminent)

                MultiSelectRow(showSelectButton: visible, selected: selected) {
                    HStack {
                        Text("Hello World")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                } onSelectionToggled: {
                    withAnimation {
                        selected.toggle()
                    }
                }
                .selectButtonStyle(tintColor: .black, checkColor: .white)
                .padding()
                .background(Color.blue)

            }
            .frame(maxWidth: .infinity)
        }
    }
}
