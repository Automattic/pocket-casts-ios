import SwiftUI

struct EmptyDataView: View {

    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> ())?

    init(title: String, subtitle: String? = nil, actionTitle: String? = nil, action: (() -> ())? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text(title)
                .font(.title)
                .foregroundStyle(Color.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
            }
            if let actionTitle {
                Button(actionTitle) {
                    action?()
                }
            }
            Spacer()
        }
    }
}

#Preview {
    EmptyDataView(title: "Empty Title", subtitle: "No results to see here!", actionTitle: "Do something", action: nil)
}
