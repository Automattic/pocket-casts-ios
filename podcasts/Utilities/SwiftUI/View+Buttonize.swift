import SwiftUI

extension View {
    /// Wraps the view in a basic button that performs the action when tapped
    func buttonize(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            self
        }
    }

    /// Wraps the view in a button that performs the action when tapped
    /// and calls `onPressed` when the buttons pressed state changes
    func buttonize(_ action: @escaping () -> Void, onPressed: @escaping (Bool) -> Void) -> some View {
        Button(action: action) {
            self
        }
        .buttonStyle(OnPressedActionButtonStyle(onPressed: onPressed))
    }

    /// Wraps the view in a button that performs the action when tapped
    /// and calls customize to allow for one-off button style customization without needing to create a ButtonStyle struct
    func buttonize<Content: View>(_ action: @escaping () -> Void, customize: @escaping (ButtonStyle.Configuration) -> Content) -> some View {
        Button(action: action) {
            self
        }
        .buttonStyle(DynamicButtonStyle(customize))
    }
}

// MARK: - DynamicButtonStyle

/// A `ButtonStyle` that allows the view to customize the button without needing to create a ButtonStyle struct
///
/// Use `.buttonize(action:customize)`
struct DynamicButtonStyle<Content: View>: ButtonStyle {
    let buttonContent: (ButtonStyle.Configuration) -> Content

    init(_ buttonContent: @escaping (ButtonStyle.Configuration) -> Content) {
        self.buttonContent = buttonContent
    }

    func makeBody(configuration: Configuration) -> some View {
        buttonContent(configuration)
    }
}

// MARK: - PressedButtonStyle

/// A `ButtonStyle` that calls the `onPressed` closure when the view is tapped
///
/// Use `.buttonize(action:onPressed)`
struct OnPressedActionButtonStyle: ButtonStyle {
    let onPressed: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .onChange(of: configuration.isPressed, perform: { newValue in
                onPressed(newValue)
            })
    }
}
