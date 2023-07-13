import SwiftUI

/// A list view wrapper that can toggle a selection checkbox visible
///
/// See the [Preview](x-source-tag://MultiSelectRowPreview) for example usage
struct MultiSelectRow<Content: View>: View {
    let visible: Bool
    let selected: Bool
    let content: () -> Content
    let onSelectionToggled: () -> Void

    @ScaledMetricWithMaxSize(relativeTo: .body) private var multiSelectButtonSize = 24
    @ScaledMetricWithMaxSize(relativeTo: .body) private var checkSize = 20

    private let style = Style()

    var body: some View {
        HStack(spacing: 15) {
            if visible {
                buttonView.buttonize {
                    onSelectionToggled()
                } customize: { config in
                    config.label.applyButtonEffect(isPressed: config.isPressed)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            content()
        }
    }

    func rowStyle(tintColor: Color, checkColor: Color) -> Self {
        style.tint = tintColor
        style.check = checkColor
        return self
    }

    private var buttonView: some View {
        Circle()
            .stroke(lineWidth: 2)
            .fill(style.tint)
            .frame(width: multiSelectButtonSize, height: multiSelectButtonSize)
            .overlay(selectedView)
    }

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

                MultiSelectRow(visible: visible, selected: selected) {
                    HStack {
                        Text("Hello World")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                } onSelectionToggled: {
                    withAnimation {
                        selected.toggle()
                    }
                }
                .rowStyle(tintColor: .black, checkColor: .white)
                .padding()
                .background(Color.blue)

            }
            .frame(maxWidth: .infinity)
        }
    }
}
