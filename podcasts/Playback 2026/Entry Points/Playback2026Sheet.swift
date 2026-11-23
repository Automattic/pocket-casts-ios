import SwiftUI

/// The announcement shown over the Podcasts tab when Playback 2026 becomes available.
struct Playback2026Sheet: View {
    @EnvironmentObject private var theme: Theme

    let onViewPlayback: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ModalTopPill(fillColor: theme.activeTheme.isDark ? .white : .gray)
                .padding(.bottom, 28)

            VStack(spacing: 20) {
                Image("playback-2026-sheet")
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityHidden(true)

                Text(L10n.playback2026SheetDescription)
                    .font(size: 14, style: .footnote, weight: .medium, maxSizeCategory: .accessibilityMedium)
                    .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Button(L10n.playback2026SheetButton, action: onViewPlayback)
                    .buttonStyle(RoundedButtonStyle(theme: theme, backgroundColor: Color(hex: "E00035")))
                    .frame(minHeight: 56)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: 600)
        .applyDefaultThemeOptions()
        .onAppear {
            Playback2026.hasShownSheet = true
            Playback2026Analytics.track(.endOfYearModalShown)
        }
    }
}

#Preview {
    Playback2026Sheet(onViewPlayback: {})
        .environmentObject(Theme(previewTheme: .light))
}
