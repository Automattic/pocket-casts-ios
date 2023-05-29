import Foundation
import SwiftUI

struct ThemedSwitchToggleStyle: ToggleStyle {
    @EnvironmentObject var theme: Theme

    var onColor: Color {
        ThemeColor.primaryInteractive01(for: theme.activeTheme).color
    }

    var offColor: Color {
        ThemeColor.primaryInteractive03(for: theme.activeTheme).color
    }

    var thumbColor: Color {
        ThemeColor.primaryInteractive02(for: theme.activeTheme).color
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16, style: .circular)
                .fill(configuration.isOn ? onColor : offColor)
                .frame(width: 50, height: 29)
                .overlay(
                    Circle()
                        .fill(thumbColor)
                        .shadow(radius: 1, x: 0, y: 1)
                        .padding(1.5)
                        .offset(x: configuration.isOn ? 10 : -10))
                .animation(Animation.easeInOut(duration: 0.1), value: configuration.isOn)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

extension ToggleStyle where Self == ThemedSwitchToggleStyle {
    static var themedSwitch: ThemedSwitchToggleStyle { .init() }
}
