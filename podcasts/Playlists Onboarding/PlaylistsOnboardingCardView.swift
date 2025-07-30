import SwiftUI

enum PlaylistsOnboardingCard: CaseIterable, Identifiable {
    case smartPlaylist
    case manualPlaylist

    var id: Self {
        return self
    }

    var title: String {
        switch self {
        case .smartPlaylist:
            return L10n.playlistsOnboardingSmartTitle
        case .manualPlaylist:
            return L10n.playlistsOnboardingManualTitle
        }
    }

    var description: String {
        switch self {
        case .smartPlaylist:
            return L10n.playlistsOnboardingSmartDescription
        case .manualPlaylist:
            return L10n.playlistsOnboardingManualDescription
        }
    }

    var imageName: String {
        switch self {
        case .smartPlaylist:
            return "playlist_onboarding_smart"
        case .manualPlaylist:
            return "playlist_onboarding_manual"
        }
    }
}

struct PlaylistsOnboardingCardView: View {
    @EnvironmentObject var theme: Theme

    let card: PlaylistsOnboardingCard

    var body: some View {
        VStack(spacing: 24.0) {
            HStack {
                Spacer()
                Image(card.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 278, height: 279)
                Spacer()
            }
            .padding(.top, 50.0)
            VStack(spacing: 16.0) {
                Text(card.title)
                    .font(size: 31, style: .body, weight: .bold)
                    .foregroundStyle(theme.primaryText01)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                Text(card.description)
                    .font(size: 15.0, style: .body, weight: .regular)
                    .foregroundStyle(theme.primaryText02)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 48.0)
            Spacer()
        }
    }
}

#Preview {
    PlaylistsOnboardingCardView(card: .smartPlaylist)
        .environmentObject(Theme.sharedTheme)
}
