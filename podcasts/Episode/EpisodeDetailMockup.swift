import SwiftUI

// MARK: - Episode Detail Redesign Mockup

/// Visual mockup for the proposed episode detail page redesign.
/// This file is for design exploration only — not wired to real data.
struct EpisodeDetailMockup: View {
    @EnvironmentObject private var theme: Theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                playSection
                actionsRow
                summaryCard
                intelligenceRow
                showNotesSection
            }
        }
        .background(AppTheme.color(for: .primaryUi01, theme: theme))
    }

    // MARK: - Header (artwork + title + metadata)

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Podcast artwork
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.6), Color.cyan.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 175, height: 175)
                .overlay(
                    VStack(spacing: 4) {
                        Text("The")
                            .font(.system(size: 24, weight: .bold, design: .serif))
                        Text("Daily")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                    }
                    .foregroundStyle(.white)
                )
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

            // Episode title
            Text("A Trump Dissenter Fights for His Political Life")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))
                .multilineTextAlignment(.center)

            // Podcast name + duration
            HStack(spacing: 6) {
                Text("The Daily")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.color(for: .primaryInteractive01, theme: theme))
                Text("·")
                    .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
                Text("May 19, 2026")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
                Text("·")
                    .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
                Text("34 min")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Play Button + Star + More

    private var playSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Spacer()

                // Star
                Image(systemName: "star")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.color(for: .primaryIcon02, theme: theme))

                // Play button
                Button(action: {}) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.color(for: .primaryInteractive02, theme: theme))
                        .frame(width: 64, height: 64)
                        .background(AppTheme.color(for: .primaryInteractive01, theme: theme))
                        .clipShape(Circle())
                }

                // More menu
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.color(for: .primaryIcon02, theme: theme))

                Spacer()
            }

            // Progress bar
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.color(for: .primaryUi05, theme: theme))
                        .frame(height: 3)
                    Capsule()
                        .fill(AppTheme.color(for: .primaryInteractive01, theme: theme))
                        .frame(width: proxy.size.width * 0.35, height: 3)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 40)
        }
        .padding(.bottom, 20)
    }

    // MARK: - AI Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.color(for: .primaryInteractive01, theme: theme))
                Text("Summary")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.color(for: .primaryInteractive01, theme: theme))
                Spacer()
            }

            Text("In Kentucky today, amid record-low approval ratings, President Trump is asking Republican primary voters to reject Representative Thomas Massie, who has broken with Mr. Trump on a handful of key issues. The episode explores what this race reveals about loyalty and dissent within the modern Republican party.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))
                .lineSpacing(3)
                .lineLimit(4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.color(for: .primaryUi02, theme: theme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppTheme.color(for: .primaryUi05, theme: theme), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Intelligence Row (Transcript, Chat, Bookmarks)

    private var intelligenceRow: some View {
        HStack(spacing: 10) {
            intelligenceCard(
                icon: "text.quote",
                label: "Transcript",
                badge: "Auto"
            )
            intelligenceCard(
                icon: "bubble.left.and.text.bubble.right",
                label: "Chat",
                badge: nil
            )
            intelligenceCard(
                icon: "bookmark",
                label: "Bookmarks",
                badge: "3"
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    private func intelligenceCard(icon: String, label: String, badge: String?) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.color(for: .primaryInteractive01, theme: theme))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)

                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.color(for: .primaryInteractive02, theme: theme))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(AppTheme.color(for: .primaryInteractive01, theme: theme))
                        )
                        .offset(x: 4, y: -4)
                }
            }

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.color(for: .primaryUi02, theme: theme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppTheme.color(for: .primaryUi05, theme: theme), lineWidth: 1)
        )
    }

    // MARK: - Show Notes

    private var showNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Show Notes")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
                .textCase(.uppercase)

            Text("In Kentucky today, amid record-low approval ratings, President Trump is asking Republican primary voters to reject Representative Thomas Massie, who has broken with Mr. Trump on a handful of key issues. We look at what this primary fight tells us about the direction of the Republican Party.\n\nGuest: Jonathan Weisman, a political correspondent for The New York Times.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))
                .lineSpacing(3)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Action Buttons Row

    private var actionsRow: some View {
        HStack(spacing: 0) {
            actionButton(
                icon: "checkmark.circle.fill",
                label: "66.3 MB",
                tint: AppTheme.color(for: .primaryInteractive01, theme: theme)
            )
            actionButton(
                icon: "plus",
                label: "Add",
                tint: AppTheme.color(for: .primaryInteractive01, theme: theme)
            )
            actionButton(
                icon: "checkmark",
                label: "Mark\nPlayed",
                tint: AppTheme.color(for: .primaryIcon01, theme: theme)
            )
            actionButton(
                icon: "archivebox",
                label: "Archive",
                tint: AppTheme.color(for: .primaryIcon01, theme: theme)
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    private func actionButton(icon: String, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(tint)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 52)
    }
}

// MARK: - Previews

#Preview("Light") {
    EpisodeDetailMockup()
        .environmentObject(Theme(previewTheme: .light))
}

#Preview("Dark") {
    EpisodeDetailMockup()
        .environmentObject(Theme(previewTheme: .dark))
}

#Preview("Extra Dark") {
    EpisodeDetailMockup()
        .environmentObject(Theme(previewTheme: .extraDark))
}

#Preview("Indigo") {
    EpisodeDetailMockup()
        .environmentObject(Theme(previewTheme: .indigo))
}
