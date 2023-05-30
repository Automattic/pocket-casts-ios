import SwiftUI

struct ReadOnlyTextView: View {
    @EnvironmentObject var theme: Theme
    @State private var lines: [String]

    init(text: String) {
        // break text up into lines, to let the scroll view be lazy so we can avoid excessive memory usage from huge text views
        lines = text.components(separatedBy: "\n")
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(lines.indices, id: \.self) { line in
                    Text(lines[line])
                        .lineLimit(Int.max)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
        }
        .frame(maxWidth: .infinity, minHeight: 25, maxHeight: 300, alignment: .leading)
        .foregroundColor(ThemeColor.primaryText01(for: theme.activeTheme).color)
        .overlay(
            RoundedRectangle(cornerRadius: ViewConstants.cornerRadius).stroke(
                ThemeColor.primaryUi05(for: theme.activeTheme).color,
                lineWidth: 1
            )
        )
        .background(ThemeColor.primaryUi02(for: theme.activeTheme).color.cornerRadius(ViewConstants.cornerRadius))
        .contextMenu {
            Button(L10n.copy) {
                UIPasteboard.general.string = lines.joined(separator: "\n")
            }
        }
    }
}
