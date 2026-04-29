import SwiftUI

struct EmptyView: View {

    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> ())?

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
    EmptyView(title: "Empty Title", subtitle: "No results to see here!", actionTitle: "Do something", action: nil)
}
