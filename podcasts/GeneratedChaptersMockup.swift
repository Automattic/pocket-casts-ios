import SwiftUI

// MARK: - Generated Chapters Opt-In Mockup

/// Visual mockup for the generated chapters opt-in feature.
/// Shows the podcast settings row, What's New announcement, and global setting.
/// This file is for design exploration only — not wired to real data.

// MARK: - 1. Podcast Settings Sheet Row

private struct PodcastSettingsSheetMockup: View {
    @EnvironmentObject private var theme: Theme

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
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
                    // Section 1: Toggles
                    settingsSection {
                        switchRow(icon: "arrow.down.circle", label: "Auto Download", isOn: true)
                        divider()
                        switchRow(icon: "bell", label: "Notifications", isOn: false)
                        divider()
                        switchRow(icon: "text.line.first.and.arrowtriangle.forward", label: "Add to Up Next", isOn: false)
                    }

                    // Section 2: Playback
                    settingsSection {
                        disclosureRow(icon: "slider.horizontal.3", label: "Playback Effects", detail: "Off")
                        divider()
                        stepperRow(icon: "forward", label: "Skip First", value: "0 sec")
                        divider()
                        stepperRow(icon: "backward", label: "Skip Last", value: "0 sec")
                        divider()
                        // ★ NEW ROW — Generated Chapters (free user, locked)
                        generatedChaptersRow(isLocked: true, isOn: false)
                    } footer: {
                        Text("Automatically generate chapters for episodes without them. Requires Pocket Casts Plus.")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
                            .padding(.horizontal, 16)
                            .padding(.top, 6)
                            .padding(.bottom, 16)
                    }

                    // Section 3: Archive
                    settingsSection {
                        disclosureRow(icon: "archivebox", label: "Auto Archive", detail: nil)
                    }

                    // Section 4: Global
                    settingsSection {
                        disclosureRow(icon: "gearshape", label: "Global Settings", detail: nil)
                    }

                    // Section 5: Destructive
                    settingsSection {
                        HStack {
                            Spacer()
                            Text("Unsubscribe")
                                .font(.system(size: 17))
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .frame(height: 44)
                    }
                }
                .padding(.top, 8)
            }
        }
        .background(AppTheme.color(for: .primaryUi02, theme: theme))
    }

    // MARK: - Generated Chapters Row

    private func generatedChaptersRow(isLocked: Bool, isOn: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "list.bullet.indent")
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.color(for: .primaryIcon01, theme: theme))
                .frame(width: 28, height: 28)

            Text("Generated Chapters")
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))

            Spacer()

            if isLocked {
                // Locked state — show Plus badge
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
                // Unlocked — show toggle
                Toggle("", isOn: .constant(isOn))
                    .labelsHidden()
                    .tint(Color.cyan)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }

    // MARK: - Reusable Cell Types

    private func switchRow(icon: String, label: String, isOn: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.color(for: .primaryIcon01, theme: theme))
                .frame(width: 28, height: 28)
            Text(label)
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))
            Spacer()
            Toggle("", isOn: .constant(isOn))
                .labelsHidden()
                .tint(Color.cyan)
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }

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

    @ViewBuilder
    private func settingsSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        settingsSection(content: content) { EmptyView() }
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
        .padding(.bottom, 8)
    }

    private func divider() -> some View {
        Divider()
            .padding(.leading, 56)
    }
}

// MARK: - 2. What's New Announcement

private struct WhatsNewAnnouncementMockup: View {
    @EnvironmentObject private var theme: Theme
    let variant: Variant

    enum Variant {
        case plus      // Subscribed user
        case free      // Free user — upgrade prompt
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header illustration
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.5, blue: 0.9),
                        Color(red: 0.3, green: 0.7, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: "list.bullet.indent")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                        Text("Auto")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(height: 195)

            // Content
            VStack(spacing: 16) {
                Text("Generated Chapters")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))

                Text(message)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 24)

                Button(action: {}) {
                    Text(buttonTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.color(for: .primaryInteractive01, theme: theme))
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            .padding(.vertical, 24)
        }
        .background(AppTheme.color(for: .primaryUi01, theme: theme))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .padding(.horizontal, 24)
    }

    private var message: String {
        switch variant {
        case .plus:
            return "Podcasts without chapters can now have them generated automatically. Turn it on in Podcast Settings or enable it globally in Settings."
        case .free:
            return "Podcasts without chapters can now have them generated automatically. Upgrade to Pocket Casts Plus to unlock this feature."
        }
    }

    private var buttonTitle: String {
        switch variant {
        case .plus: return "Enable in Settings"
        case .free: return "Upgrade to Plus"
        }
    }
}

// MARK: - 3. Podcast Settings (Plus user, unlocked & enabled)

private struct PodcastSettingsUnlockedMockup: View {
    @EnvironmentObject private var theme: Theme

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

            VStack(spacing: 0) {
                // Only showing the playback section for clarity
                VStack(spacing: 0) {
                    disclosureRow(icon: "slider.horizontal.3", label: "Playback Effects", detail: "On")
                    Divider().padding(.leading, 56)
                    stepperRow(icon: "forward", label: "Skip First", value: "15 sec")
                    Divider().padding(.leading, 56)
                    stepperRow(icon: "backward", label: "Skip Last", value: "30 sec")
                    Divider().padding(.leading, 56)
                    // ★ Unlocked and toggled ON
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet.indent")
                            .font(.system(size: 17))
                            .foregroundStyle(AppTheme.color(for: .primaryIcon01, theme: theme))
                            .frame(width: 28, height: 28)
                        Text("Generated Chapters")
                            .font(.system(size: 17))
                            .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                            .tint(Color.cyan)
                    }
                    .frame(height: 44)
                    .padding(.horizontal, 16)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.color(for: .primaryUi01, theme: theme))
                )
                .padding(.horizontal, 16)

                Text("Chapters will be automatically generated for episodes in this podcast that don't have their own.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
            }
            .padding(.top, 16)

            Spacer()
        }
        .background(AppTheme.color(for: .primaryUi02, theme: theme))
    }

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
}

// MARK: - Previews

#Preview("1. Settings — Free User (Locked)") {
    PodcastSettingsSheetMockup()
        .environmentObject(Theme(previewTheme: .light))
}

#Preview("2. Settings — Plus User (Enabled)") {
    PodcastSettingsUnlockedMockup()
        .environmentObject(Theme(previewTheme: .light))
}

#Preview("3. What's New — Plus User") {
    ZStack {
        Color.black.opacity(0.4).ignoresSafeArea()
        WhatsNewAnnouncementMockup(variant: .plus)
            .environmentObject(Theme(previewTheme: .light))
    }
}

#Preview("4. What's New — Free User") {
    ZStack {
        Color.black.opacity(0.4).ignoresSafeArea()
        WhatsNewAnnouncementMockup(variant: .free)
            .environmentObject(Theme(previewTheme: .light))
    }
}

#Preview("5. Settings — Dark Theme (Locked)") {
    PodcastSettingsSheetMockup()
        .environmentObject(Theme(previewTheme: .dark))
}
