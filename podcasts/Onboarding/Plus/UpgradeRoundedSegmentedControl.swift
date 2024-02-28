import Foundation
import SwiftUI

struct UpgradeRoundedSegmentedControl: View {
    @EnvironmentObject var theme: Theme

    @Binding private var selected: PlanFrequency

    init(selected: Binding<PlanFrequency>) {
        self._selected = selected
    }

    var body: some View {
        HStack(spacing: 0) {
            Button(L10n.yearly) {
                withAnimation {
                    selected = .yearly
                }
            }
            .buttonStyle(UpgradeSegmentedControlButtonStyle(isSelected: selected == .yearly, theme: theme))
            .padding(4)

            Button(L10n.monthly) {
                withAnimation {
                    selected = .monthly
                }
            }
            .buttonStyle(UpgradeSegmentedControlButtonStyle(isSelected: selected == .monthly, theme: theme))
            .padding(4)
        }
        .background(theme.primaryUi05)
        .cornerRadius(24)
    }
}

struct UpgradeSegmentedControlButtonStyle: ButtonStyle {
    let isSelected: Bool
    let theme: Theme

    init(isSelected: Bool = true, theme: Theme) {
        self.isSelected = isSelected
        self.theme = theme
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? theme.primaryUi01 : configuration.isPressed ? theme.primaryUi01 : theme.primaryUi05
            )
            .font(style: .subheadline, weight: .medium)
            .foregroundColor(isSelected ? theme.primaryText01 : theme.primaryText02)
            .cornerRadius(100)
            .contentShape(Rectangle())
    }
}
