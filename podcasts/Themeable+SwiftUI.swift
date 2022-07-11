import Foundation
import SwiftUI
import UIKit

public enum ViewConstants {
    static let cornerRadius: CGFloat = 5
}

extension View {
    func applyDefaultThemeOptions(backgroundOverride: ThemeStyle = .primaryUi01) -> some View {
        modifier(DefaultThemeSettings(backgroundOverride: backgroundOverride))
    }
    
    func required(_ hasErrored: Bool) -> some View {
        modifier(RequiredInput(hasErrored))
    }
    
    func themedTextField(style: ThemeStyle = .primaryUi02, hasErrored: Bool = false) -> some View {
        modifier(ThemedTextField(style: style, hasErrored: hasErrored))
    }
    
    func requiredStyle(_ hasErrored: Bool) -> some View {
        textFieldStyle(RequiredFieldStyle(hasErrored: hasErrored))
    }

    func navThemed() -> some View {
        buttonStyle(NavButtonStyle())
    }
}
