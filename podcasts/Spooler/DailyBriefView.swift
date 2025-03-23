import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import AVFoundation

private struct SafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}

struct DailyBriefView: View {
    @State private var selectedDuration = "Short"
    @State private var isShowingCustomOptions = false
    @State private var isShowingPreferences = false
    @State private var customServices: [String: String] = [:]
    @State private var preferences = Preferences(
        selectedOptions: [
            .location: ["San Francisco"],
            .news: ["General"],
            .sports: ["General"],
            .stocks: ["AAPL", "GOOG"],
            .emailNewsletters: ["Morning Brew"]
        ],
        birthday: nil
    )

    // Use the player manager to handle all playback logic
    @StateObject private var playerManager = BriefPlayerManager()

    private let durations = ["Short", "Medium", "Long", "Custom"]
    @Environment(\.safeAreaInsets) var safeAreaInsets

    var body: some View {
        VStack(spacing: 24) {
            // Duration options grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(durations, id: \.self) { duration in
                    DurationCell(
                        title: duration,
                        isSelected: selectedDuration == duration
                    )
                    .onTapGesture {
                        if duration == "Custom" {
                            isShowingCustomOptions = true
                        }
                        selectedDuration = duration
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)

            // Progress text
            if let text = playerManager.progressText {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(Color(ThemeColor.primaryText02()))
                    .padding(.top, 8)
            }

            Spacer()
                .frame(maxHeight: 100) // Limit spacer height

            VStack(spacing: 16) {
                // Play button
                Button(action: {
                    if playerManager.isPlaying {
                        playerManager.pausePlayback()
                    } else {
                        Task {
                            do {
                                try await playerManager.playBrief(
                                    duration: BriefDuration(rawValue: selectedDuration.lowercased()) ?? .short,
                                    customServices: customServices
                                )
                            } catch {
                                print("Error: \(error)")
                            }
                        }
                    }
                }) {
                    Text(playerManager.isLoading ? "Loading..." : (playerManager.isPlaying ? "Stop" : "Play"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(ThemeColor.primaryInteractive01()))
                        .cornerRadius(22)
                }
                .disabled(playerManager.isLoading)
                .padding(.horizontal)

                // Reset button
                Button(action: {
                    playerManager.resetPlayback()
                }) {
                    Text("Reset")
                        .font(.system(size: 15))
                        .foregroundColor(Color(ThemeColor.primaryInteractive01()))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, safeAreaInsets.bottom > 0 ? 16 : 32)

            if safeAreaInsets.bottom > 0 {
                Spacer()
                    .frame(height: safeAreaInsets.bottom)
            }
        }
        .navigationTitle("Your Daily Brief")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isShowingPreferences = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(Color(ThemeColor.primaryInteractive01()))
                }
            }
        }
        .sheet(isPresented: $isShowingCustomOptions) {
            CustomOptionsView { services in
                customServices = services
            }
        }
        .sheet(isPresented: $isShowingPreferences) {
            PreferencesView(preferences: preferences) { newPreferences in
                preferences = newPreferences
            }
        }
        .edgesIgnoringSafeArea([.bottom])
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(ThemeColor.primaryUi01()))
        .onDisappear {
            playerManager.pausePlayback()
        }
    }
}

struct DurationCell: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(ThemeColor.primaryUi02()))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            Color(isSelected ? ThemeColor.primaryInteractive01() : ThemeColor.primaryUi05()),
                            lineWidth: 2
                        )
                )

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(ThemeColor.primaryText01()))
        }
        .frame(height: 56)
        .background(
            isSelected ? Color(ThemeColor.primaryInteractive01()).opacity(0.1) : Color.clear
        )
    }
}

extension UIEdgeInsets {
    var swiftUIInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

#Preview {
    DailyBriefView()
}
