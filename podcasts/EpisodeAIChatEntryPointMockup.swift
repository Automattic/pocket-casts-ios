import SwiftUI

// MARK: - Player AI Chat Entry Point Mockup (Spotify-style)
// Self-contained mockup — delete after review

private struct PlayerAIChatMockup: View {
    @State private var isPromptFocused = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 12)
                albumArt
                episodeInfo
                timeSlider
                playbackControls
                shelfActions
                aiPromptBar
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Album Art

    private var albumArt: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.6))
                    Text("The Daily")
                        .font(.title2.bold())
                        .foregroundColor(.white.opacity(0.8))
                }
            )
            .padding(.horizontal, 20)
    }

    // MARK: - Episode Info

    private var episodeInfo: some View {
        VStack(spacing: 4) {
            Text("Trump's National Support Is Cratering")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text("The Daily")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }

    // MARK: - Time Slider

    private var timeSlider: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: geo.size.width * 0.08, height: 4)
                }
            }
            .frame(height: 4)

            HStack {
                Text("1:03")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("-30:02")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                Text("1.5")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Text("x")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.8))
            .frame(width: 44, height: 44)

            Spacer()

            Image(systemName: "gobackward.15")
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)

            Spacer()

            Circle()
                .fill(Color.white)
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "pause.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                )

            Spacer()

            Image(systemName: "goforward.15")
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)

            Spacer()

            Image(systemName: "moon.fill")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 44, height: 44)

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Shelf Actions

    private var shelfActions: some View {
        HStack(spacing: 0) {
            shelfButton(icon: "slider.horizontal.3", label: "Effects")
            shelfButton(icon: "airplayaudio", label: "AirPlay")
            shelfButton(icon: "square.and.arrow.up", label: "Share")
            shelfButton(icon: "star", label: "Star")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .padding(.top, 16)
    }

    private func shelfButton(icon: String, label: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 18))
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 40)
    }

    // MARK: - AI Prompt Bar (Spotify-style entry point)

    private var aiPromptBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))

            Text("Ask about this episode...")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.35))

            Spacer()

            Text("NEW")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.08))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.top, 16)
    }
}

#Preview("Player — AI Prompt Bar") {
    PlayerAIChatMockup()
}
