import SwiftUI

@Observable
class WelcomeViewModel {
    var podcasts: [MockPodcast] = MockData.makePodcasts()
}

struct WelcomeView: View {
    @Environment(AppCoordinator.self) var coordinator

    @State var model = WelcomeViewModel()

    enum Layout {
        static let gridSize = CGFloat(272)
    }

    let items: [GridItem] = (0..<8).map { _ in
        GridItem(.fixed(Layout.gridSize))
    }

    enum Destination: Hashable {
        case signIn
        case createAccount
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                podcastGrid
                gradientView
                VStack(spacing: 32) {
                    Spacer()
                    Image(ImageResource.pcLogo)
                    Text(L10n.tvWelcomeTitle)
                        .font(.title)
                    Text(L10n.tvWelcomeSubtitle)
                        .font(.headline)
                        .foregroundColor(Color.textSecondary)
                    HStack {
                        NavigationLink(value: Destination.signIn) {
                            Text(L10n.tvWelcomeSignIn)
                        }
                        NavigationLink(value: Destination.createAccount) {
                            Text(L10n.tvWelcomeCreateFreeAccount)
                        }
                    }
                    Spacer()
                    Button(L10n.tvWelcomeBrowseWithoutAccount) {
                        coordinator.state = .browsing
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color.textSecondary)
                }
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .signIn:
                    SignInView()
                case .createAccount:
                    CreateAccountView()
                }
            }
        }
    }

    var podcastGrid: some View {
        LazyVGrid(columns: items, content: {
            ForEach(model.podcasts) { podcast in
                Image(podcast.image)
                    .resizable()
                    .frame(width: Layout.gridSize, height: Layout.gridSize)
            }
        }).ignoresSafeArea()
    }

    var gradientView: some View {
        Rectangle()
          .foregroundColor(.clear)
          .background(
            LinearGradient(
              stops: [
                Gradient.Stop(color: Color.backgroundSurface, location: 0.00),
                Gradient.Stop(color: Color.backgroundSurface.opacity(0.5), location: 1.00),
              ],
              startPoint: UnitPoint(x: 0.5, y: 0.41),
              endPoint: UnitPoint(x: 0.5, y: 0.13)
            )
          )
    }
}

#Preview {
    WelcomeView()
        .environment(AppCoordinator())
}
