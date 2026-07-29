import SwiftUI

// MARK: - Generated Chapters Opt-In Mockup

/// Visual mockup for the generated chapters opt-in experience in the player Chapters tab.
/// Shows three states: opt-in prompt (default/off), enabled with chapters, and podcast settings.
/// This file is for design exploration only — not wired to real data.

// MARK: - Sample Chapter Data

private struct SampleChapter: Identifiable {
    let id: Int
    let title: String
    let duration: String
    var isCurrent: Bool = false
}

private let sampleChapters: [SampleChapter] = [
    .init(id: 1, title: "Confirmation Hearings Begin for Todd Blanche", duration: "3m"),
    .init(id: 2, title: "Blanche's Background and Connection to Trump", duration: "5m"),
    .init(id: 3, title: "Blanche's Legal Strategy and Approach", duration: "3m"),
    .init(id: 4, title: "Blanche's Role in Trump's Second Term", duration: "5m"),
    .init(id: 5, title: "Concerns Over the Department of Justice's Integrity", duration: "6m", isCurrent: true),
    .init(id: 6, title: "Blanche's Uncertain Future with Senate Confirmation", duration: "6m"),
]

// MARK: - 1. Player Chapters Tab — Opt-In Prompt (Default State)

/// Shown when generated chapters are available but the user hasn't opted in.
/// The feature is off by default — this is the first thing users see.
private struct ChaptersOptInMockup: View {
    @EnvironmentObject private var theme: Theme

    var body: some View {
        VStack(spacing: 0) {
            playerTabBar

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 40)

                    // Sparkles icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))

                    // Title
                    Text("Generated Chapters")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    // Description
                    Text("This episode doesn't have chapters. Pocket Casts can generate them automatically so you can navigate by topic.")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 32)

                    // Enable button
                    Button(action: {}) {
                        Text("Generate Chapters")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                Capsule()
                                    .fill(.white)
                            )
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 4)

                    // Disclaimer
                    Text("Chapters are generated using AI and may not be perfectly accurate.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(red: 0.08, green: 0.11, blue: 0.14))
    }
}

// MARK: - 2. Player Chapters Tab — Enabled (Chapters Visible)

/// Shown after the user opts in and chapters have been generated.
/// The "..." button uses a Menu (pull-down) instead of an action sheet,
/// following iOS 26 HIG best practices:
/// - Menu is the correct pattern for a deliberate tap-to-reveal interaction
/// - Keeps the user in context (no full-screen sheet sliding up)
/// - Supports .destructive role, icons, subtitles, and sections
/// - .menuOrder(.fixed) keeps items in declared order
private struct ChaptersEnabledMockup: View {
    @EnvironmentObject private var theme: Theme
    @State private var isPreselectingChapters = false

    var body: some View {
        VStack(spacing: 0) {
            playerTabBar

            // Generated indicator header with Menu pull-down
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                Text("\(sampleChapters.count) Generated Chapters")
                    .font(.system(size: 12, weight: .medium))

                Spacer()

                // ★ Pull-down Menu — replaces bottom action sheet
                Menu {
                    // Primary action
                    Button {
                        isPreselectingChapters.toggle()
                    } label: {
                        Label("Preselect Chapters", systemImage: "checkmark.circle")
                    }

                    // Destructive section — grouped together
                    Section {
                        Button(role: .destructive) {
                            // disable for this podcast
                        } label: {
                            Label("Turn Off for This Podcast", systemImage: "minus.circle")
                        }

                        Button(role: .destructive) {
                            // disable globally
                        } label: {
                            Label("Turn Off for All Podcasts", systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .menuOrder(.fixed)
            }
            .foregroundStyle(.white.opacity(0.45))
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, 6)

            Divider()
                .background(.white.opacity(0.1))

            // Chapter list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(sampleChapters) { chapter in
                        chapterRow(chapter: chapter)
                    }
                }
            }
        }
        .background(Color(red: 0.08, green: 0.11, blue: 0.14))
    }

    private func chapterRow(chapter: SampleChapter) -> some View {
        HStack(spacing: 12) {
            Text("\(chapter.id)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(chapter.isCurrent ? .white : .white.opacity(0.5))
                .frame(width: 24)

            Text(chapter.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(chapter.isCurrent ? .white : .white.opacity(0.7))
                .lineLimit(2)

            Spacer()

            Text(chapter.duration)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(chapter.isCurrent ? .white : .white.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            chapter.isCurrent
                ? AnyShapeStyle(.white.opacity(0.1))
                : AnyShapeStyle(.clear)
        )
    }
}

// MARK: - 3. Player Chapters Tab — Loading State

/// Shown while chapters are being generated after the user taps "Generate Chapters".
private struct ChaptersLoadingMockup: View {
    @EnvironmentObject private var theme: Theme

    var body: some View {
        VStack(spacing: 0) {
            playerTabBar

            Spacer()

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white.opacity(0.6))
                    .scaleEffect(1.2)

                Text("Generating chapters…")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()
        }
        .background(Color(red: 0.08, green: 0.11, blue: 0.14))
    }
}

// MARK: - 4. Podcast Settings Row

private struct PodcastSettingsRowMockup: View {
    @EnvironmentObject private var theme: Theme
    let isLocked: Bool
    let isOn: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Podcast Settings")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))
            }
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .background(AppTheme.color(for: .primaryUi01, theme: theme))

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    settingsSection {
                        disclosureRow(icon: "slider.horizontal.3", label: "Playback Effects", detail: "Off")
                        divider()
                        stepperRow(icon: "forward", label: "Skip First", value: "0 sec")
                        divider()
                        stepperRow(icon: "backward", label: "Skip Last", value: "0 sec")
                        divider()
                        generatedChaptersRow
                    } footer: {
                        Text("Automatically generate chapters for episodes that don't have them.")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
                            .padding(.horizontal, 16)
                            .padding(.top, 6)
                            .padding(.bottom, 16)
                    }
                }
                .padding(.top, 16)
            }
        }
        .background(AppTheme.color(for: .primaryUi02, theme: theme))
    }

    private var generatedChaptersRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.color(for: .primaryIcon01, theme: theme))
                .frame(width: 28, height: 28)

            Text("Generated Chapters")
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))

            Spacer()

            if isLocked {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                    Text("PLUS")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(red: 0.95, green: 0.75, blue: 0.2))
                )
            } else {
                Toggle("", isOn: .constant(isOn))
                    .labelsHidden()
                    .tint(Color.cyan)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }

    // MARK: - Reusable Rows

    private func disclosureRow(icon: String, label: String, detail: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.color(for: .primaryIcon01, theme: theme))
                .frame(width: 28, height: 28)
            Text(label)
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))
            Spacer()
            if let detail {
                Text(detail)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.color(for: .primaryIcon03, theme: theme))
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }

    private func stepperRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.color(for: .primaryIcon01, theme: theme))
                .frame(width: 28, height: 28)
            Text(label)
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }

    private func settingsSection<Content: View, Footer: View>(
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.color(for: .primaryUi01, theme: theme))
            )
            .padding(.horizontal, 16)
            footer()
        }
    }

    private func divider() -> some View {
        Divider()
            .padding(.leading, 56)
    }
}

// MARK: - Shared Player Tab Bar

private var playerTabBar: some View {
    HStack(spacing: 0) {
        Image(systemName: "chevron.down")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.6))
            .frame(width: 44, height: 44)

        Spacer()

        HStack(spacing: 0) {
            tabBarItem("Now Playing", isSelected: false)
            tabBarItem("Details", isSelected: false)
            tabBarItem("Chapters", isSelected: true)
            tabBarItem("Bookmarks", isSelected: false)
        }

        Spacer()

        Image(systemName: "line.3.horizontal")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.6))
            .frame(width: 44, height: 44)
    }
    .padding(.horizontal, 4)
}

private func tabBarItem(_ title: String, isSelected: Bool) -> some View {
    Text(title)
        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
        .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            isSelected
                ? Capsule().fill(.white.opacity(0.15))
                : nil
        )
}

// MARK: - 5. Menu Open State (Visual Mockup)

/// Static mockup showing what the pull-down menu looks like when open.
/// Native Menu can't be rendered open in a preview, so this draws it manually.
private struct ChaptersMenuOpenMockup: View {
    @EnvironmentObject private var theme: Theme

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background: the chapters view (dimmed)
            VStack(spacing: 0) {
                playerTabBar

                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                    Text("\(sampleChapters.count) Generated Chapters")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                }
                .foregroundStyle(.white.opacity(0.45))
                .padding(.leading, 16)
                .padding(.trailing, 8)
                .padding(.vertical, 6)

                Divider()
                    .background(.white.opacity(0.1))

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sampleChapters) { chapter in
                            chapterRowDimmed(chapter: chapter)
                        }
                    }
                }
            }
            .background(Color(red: 0.08, green: 0.11, blue: 0.14))

            // Scrim overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            // Menu popover anchored to top-right
            VStack(alignment: .leading, spacing: 0) {
                // Primary action
                menuItem(
                    icon: "checkmark.circle",
                    title: "Preselect Chapters",
                    isDestructive: false
                )

                // Section separator (thicker, matching iOS menu sections)
                Rectangle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 8)

                // Destructive actions section
                menuItem(
                    icon: "minus.circle",
                    title: "Turn Off for This Podcast",
                    isDestructive: true
                )

                Divider()

                menuItem(
                    icon: "xmark.circle",
                    title: "Turn Off for All Podcasts",
                    isDestructive: true
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .frame(width: 280)
            .padding(.top, 86)
            .padding(.trailing, 16)
        }
    }

    private func menuItem(icon: String, title: String, isDestructive: Bool) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(isDestructive ? .red : .primary)
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(isDestructive ? .red : .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func chapterRowDimmed(chapter: SampleChapter) -> some View {
        HStack(spacing: 12) {
            Text("\(chapter.id)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
                .frame(width: 24)
            Text(chapter.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .lineLimit(2)
            Spacer()
            Text(chapter.duration)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Previews

#Preview("1. Opt-In Prompt (Default)") {
    ChaptersOptInMockup()
        .environmentObject(Theme(previewTheme: .dark))
}

#Preview("2. Chapters Enabled") {
    ChaptersEnabledMockup()
        .environmentObject(Theme(previewTheme: .dark))
}

#Preview("3. Loading State") {
    ChaptersLoadingMockup()
        .environmentObject(Theme(previewTheme: .dark))
}

#Preview("4. Menu Open") {
    ChaptersMenuOpenMockup()
        .environmentObject(Theme(previewTheme: .dark))
}

#Preview("5. Settings — Free User (Locked)") {
    PodcastSettingsRowMockup(isLocked: true, isOn: false)
        .environmentObject(Theme(previewTheme: .light))
}

#Preview("6. Settings — Plus (Enabled)") {
    PodcastSettingsRowMockup(isLocked: false, isOn: true)
        .environmentObject(Theme(previewTheme: .light))
}

#Preview("7. Settings — Dark (Locked)") {
    PodcastSettingsRowMockup(isLocked: true, isOn: false)
        .environmentObject(Theme(previewTheme: .dark))
}
