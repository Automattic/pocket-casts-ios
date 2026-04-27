import SwiftUI

@Observable
class WelcomeViewModel {
    var podcasts: [MockPodcast] = MockData.makePodcasts()
}

struct WelcomeView: View {
    @Environment(RootViewModel.self) var viewModel

    @State var model = WelcomeViewModel()

    enum Layout {
        static let gridSize = CGFloat(272)
    }

    let items: [GridItem] = (0..<8).map { _ in
        GridItem(.fixed(Layout.gridSize))
    }

    var body: some View {
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
                    Button(L10n.tvWelcomeSignIn) { viewModel.state = .signIn }
                        .buttonStyle(.borderedProminent)
                    Button(L10n.tvWelcomeCreateFreeAccount) { viewModel.state = .signedIn }
                        .buttonStyle(.borderedProminent)
                }
                Spacer()
                Button(L10n.tvWelcomeBrowseWithoutAccount) {
                    viewModel.state = .browsing
                }
                .buttonStyle(.plain)
                .foregroundColor(Color.textSecondary)
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
                Gradient.Stop(color: Color(red: 0.12, green: 0.13, blue: 0.14), location: 0.00),
                Gradient.Stop(color: Color(red: 0.12, green: 0.13, blue: 0.14).opacity(0.5), location: 1.00),
              ],
              startPoint: UnitPoint(x: 0.5, y: 0.41),
              endPoint: UnitPoint(x: 0.5, y: 0.13)
            )
          )
    }
}

#Preview {
    WelcomeView()
        .environment(RootViewModel())
}
