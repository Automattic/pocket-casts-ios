import SwiftUI

/// A vertical numbered checklist rendered as circular badges, shared by the TV
/// auth screens to explain the QR pairing flow.
struct StepList: View {

    let steps: [String]
    var spacing: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                stepBadge(number: index + 1, text: step)
            }
        }
    }

    private func stepBadge(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption2)
                .foregroundStyle(Color.pcTextSecondary)
                .frame(width: 40, height: 40)
                .background(Color.pcBackgroundActive20, in: Circle())
            Text(text)
                .font(.body)
                .foregroundStyle(Color.pcTextSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        // Read each step as a single unit rather than landing on the bare badge.
        .accessibilityElement(children: .combine)
    }
}
