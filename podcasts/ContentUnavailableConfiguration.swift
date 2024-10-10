import SwiftUI

@available(iOS 16, *)
// Many of these can be replaced with UIContentUnavailableConfigurations in iOS 17
struct ContentUnavailableConfiguration {
    static func loading() -> UIContentConfiguration {
        UIHostingConfiguration {
            LoadingView().environmentObject(Theme.sharedTheme)
        }
    }

    static func noNetwork(tryAgainHandler: @escaping () -> Void) -> UIContentConfiguration {
        UIHostingConfiguration {
            NoNetworkView(tryAgainHandler: tryAgainHandler).environmentObject(Theme.sharedTheme)
        }
    }

    static func noResults() -> UIContentConfiguration {
        UIHostingConfiguration {
            NoResultsView().environmentObject(Theme.sharedTheme)
        }
    }
}

struct LoadingView: View {
    @EnvironmentObject private var theme: Theme
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .padding()
                .tint(theme.primaryIcon01)
        }
    }
}

struct NoNetworkView: View {
    let tryAgainHandler: () -> Void

    @EnvironmentObject private var theme: Theme

    var body: some View {
        VStack(spacing: 16) {
            Image("discover_nointernet", label: Text("No Internet"))
            VStack(spacing: 10) {
                Text(L10n.discoverUnableToLoad)
                    .font(Font.system(size: 17))
                Text(L10n.checkInternetConnection)
                    .font(Font.system(size: 14))
            }
            .foregroundStyle(theme.primaryText01)
            Button(L10n.tryAgain) {
                tryAgainHandler()
            }
            .font(Font.system(size: 15))
            .foregroundStyle(theme.primaryInteractive01)
        }
    }
}

struct NoResultsView: View {
    @EnvironmentObject private var theme: Theme

    var body: some View {
        VStack(spacing: 12) {
            Image("discover_noresult", label: Text("No Results"))
            VStack(spacing: 10) {
                Text(L10n.discoverNoPodcastsFound)
                    .font(Font.system(size: 17))
                Text(L10n.discoverNoPodcastsFoundMsg)
                    .font(Font.system(size: 14))
            }
            .foregroundStyle(theme.primaryText01)
        }
    }
}
