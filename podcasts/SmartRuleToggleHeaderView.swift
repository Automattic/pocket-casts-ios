import SwiftUI

class SmartRuleToggleViewModel: ObservableObject {
    @Published var toggleIsOn: Bool = false
    let enabledString: String
    let disabledString: String
    let title: String

    init(toggleIsOn: Bool, title: String, enabledString: String, disabledString: String) {
        self.toggleIsOn = toggleIsOn
        self.title = title
        self.enabledString = enabledString
        self.disabledString = disabledString
    }
}

struct SmartRuleToggleHeaderView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: SmartRuleToggleViewModel

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4.0) {
                Text(viewModel.title)
                    .font(size: 18.0, style: .body, weight: .semibold)
                    .lineLimit(2)
                    .foregroundStyle(theme.primaryText01)
                let subtitle = viewModel.toggleIsOn ? viewModel.enabledString : viewModel.disabledString
                Text(subtitle)
                    .font(size: 14.0, style: .body, weight: .regular)
                    .lineLimit(2)
                    .foregroundStyle(theme.primaryText02)
            }
            Spacer()
            Toggle("", isOn: $viewModel.toggleIsOn)
                .labelsHidden()
                .tint(theme.primaryInteractive01)
        }
        .background(theme.primaryUi01)
        .padding(.horizontal, 16.0)
        .padding(.top, 10.0)
        .padding(.bottom, 22.0)
    }
}
