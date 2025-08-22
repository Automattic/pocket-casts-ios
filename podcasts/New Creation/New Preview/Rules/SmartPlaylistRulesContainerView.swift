import SwiftUI

struct SmartPlaylistRulesContainerView: View {
    @EnvironmentObject var theme: Theme

    let rules: [SmartPlaylistRuleInfo]
    let action: (SmartPlaylistRule) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(rules, id: \.id) { rule in
                SmartPlaylistRuleRowView(
                    rule: rule.type,
                    description: rule.description,
                    hideDivider: rule.type == rules.last?.type,
                    action: action
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                .fill(theme.primaryUi02Active)
        )
    }
}
