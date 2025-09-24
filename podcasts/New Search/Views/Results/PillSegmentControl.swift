import SwiftUI

struct PillSegmentControl<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {

    var data: Data

    var content: (Data.Element) -> Content

    init(
        _ data: Data,
        selection: Binding<Data.Element>,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
        self._selection = selection
    }

    @Binding var selection: Data.Element

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .center) {
                ForEach(data) { item in
                    Button(action: {
                        selection = item
                    }) {
                        content(item)
                    }
                    .buttonStyle(PillButtonStyle(isSelected: selection.id == item.id))
                }
                Spacer()
            }
        }.scrollIndicators(.hidden)
    }}


struct PillButtonStyle: ButtonStyle {

    @EnvironmentObject var theme: Theme

    private enum Constants {
        enum Padding {
            static let horizontal: CGFloat = 20
            static let vertical: CGFloat = 8
        }

        static let cornerRadius: CGFloat = 48
    }

    // MARK: Colors
    private var border: Color {
        theme.primaryField03
    }

    private var background: Color {
        theme.primaryUi01
    }

    private var pressedBackground: Color {
        theme.primaryUi02Selected
    }

    private var foreground: Color {
        theme.primaryText01
    }
    private var selectedBackground: Color {
        theme.secondaryIcon01
    }
    private var selectedForeground: Color {
        theme.secondaryUi01
    }

    // MARK: View
    let isSelected: Bool

    /// Used for generating previews with isPressed button state
    fileprivate var forcePressed = false

    init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.medium))
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, Constants.Padding.horizontal)
            .padding(.vertical, Constants.Padding.vertical)
            .cornerRadius(Constants.cornerRadius)
            .background(isSelected ? selectedBackground : ((configuration.isPressed || forcePressed) ? pressedBackground : background))
            .foregroundColor(isSelected ? selectedForeground : foreground)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .stroke(isSelected ? selectedBackground : border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
    }
}

