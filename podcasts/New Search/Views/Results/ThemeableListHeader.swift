import SwiftUI

struct ThemeableListHeader: View {
    @EnvironmentObject var theme: Theme

    let title: String

    let actionTitle: String?

    let action: (() -> ())?

    init(title: String, actionTitle: String?, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                titleView
                    .lineLimit(1)
                Spacer()
                actionButton
            }
            VStack(alignment: .leading, spacing: 8) {
                titleView
                actionButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8))
        .background(AppTheme.color(for: .primaryUi02, theme: theme))
    }

    private var titleView: some View {
        Text(title)
            .font(style: .title2, weight: .bold)
    }

    @ViewBuilder
    private var actionButton: some View {
        if let actionTitle {
            Button(actionTitle.uppercased()) {
                action?()
            }
            .font(style: .footnote, weight: .bold)
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}
