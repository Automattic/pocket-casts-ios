import SwiftUI

struct SuggestedPromptPill: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color(ThemeColor.playerContrast01()))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(ThemeColor.playerContrast05()))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color(ThemeColor.playerContrast04()), lineWidth: 0.5)
                )
        }
    }
}
