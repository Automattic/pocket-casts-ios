import SwiftUI

struct WelcomeView: View {
    @Environment(AppCoordinator.self) var coordinator

    @State var model = WelcomeViewModel()
    @State private var animating = false

    enum Layout {
        static let gridSize = CGFloat(272)
        static let gridSpacing = CGFloat(16)
        static let columnsPerRow = 8
        static let animationOffset = CGFloat(200)
        static let animationDuration = 20.0
    }

    enum Destination: Hashable {
        case signIn
        case createAccount
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .center) {
                VStack(spacing: 24) {
                    Spacer()
                    Image(ImageResource.pcLogo)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 108)
                    Text(L10n.tvWelcomeTitle)
                        .font(.title)
                    Text(L10n.tvWelcomeSubtitle)
                        .font(.headline)
                        .foregroundColor(Color.textSecondary)
                        .padding(.bottom, 16)
                    HStack(spacing: 16) {
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
            .background {
                ZStack {
                    podcastGrid
                    gradientView
                }
            }
        }
    }

    var podcastRows: [[MockPodcast]] {
        stride(from: 0, to: model.podcasts.count, by: Layout.columnsPerRow).map {
            Array(model.podcasts[$0..<min($0 + Layout.columnsPerRow, model.podcasts.count)])
        }
    }

    var podcastGrid: some View {
        VStack(spacing: Layout.gridSpacing) {
            ForEach(Array(podcastRows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: Layout.gridSpacing) {
                    ForEach(row) { podcast in
                        Image(podcast.image)
                            .resizable()
                            .frame(width: Layout.gridSize, height: Layout.gridSize)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .offset(x: animating
                    ? (rowIndex.isMultiple(of: 2) ? Layout.animationOffset : -Layout.animationOffset)
                    : (rowIndex.isMultiple(of: 2) ? -Layout.animationOffset : Layout.animationOffset))
            }
        }
        .offset(y: 40)
        .onAppear {
            withAnimation(.linear(duration: Layout.animationDuration).repeatForever(autoreverses: true)) {
                animating = true
            }
        }
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
              startPoint: UnitPoint(x: 0.5, y: 0.45),
              endPoint: UnitPoint(x: 0.5, y: 0.17)
            )
          )
    }
}

#Preview {
    WelcomeView()
        .environment(AppCoordinator())
}
