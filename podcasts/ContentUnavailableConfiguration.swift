import SwiftUI

// Many of these can be replaced with UIContentUnavailableConfigurations in iOS 17
struct ContentUnavailableConfiguration {
    static func loading() -> UIContentConfiguration {
        if #available(iOS 16.0, *) {
            return UIHostingConfiguration {
                LoadingView().environmentObject(Theme.sharedTheme)
            }
        } else {
            return HostingConfiguration {
                LoadingView().environmentObject(Theme.sharedTheme)
            }
        }
    }

    static func noNetwork(tryAgainHandler: @escaping () -> Void) -> UIContentConfiguration {
        if #available(iOS 16.0, *) {
            return UIHostingConfiguration {
                NoNetworkView(tryAgainHandler: tryAgainHandler).environmentObject(Theme.sharedTheme)
            }
        } else {
            return HostingConfiguration {
                NoNetworkView(tryAgainHandler: tryAgainHandler).environmentObject(Theme.sharedTheme)
            }
        }
    }

    static func noResults() -> UIContentConfiguration {
        if #available(iOS 16.0, *) {
            return UIHostingConfiguration {
                NoResultsView().environmentObject(Theme.sharedTheme)
            }
        } else {
            return HostingConfiguration {
                NoResultsView().environmentObject(Theme.sharedTheme)
            }
        }
    }

    static func empty() -> UIContentConfiguration {
        if #available(iOS 16.0, *) {
            return UIHostingConfiguration {
                EmptyView()
            }
        } else {
            return HostingConfiguration {
                EmptyView()
            }
        }
    }

    static func emptyState<Style: EmptyStateViewStyle>(
        title: String,
        message: String?,
        icon: (() -> Image)? = nil,
        actions: [EmptyStateAction] = [],
        style: Style = DefaultEmptyStateStyle.defaultStyle
    ) -> UIContentConfiguration {
        if #available(iOS 16.0, *) {
            return UIHostingConfiguration {
                EmptyStateView(title: title, message: message, icon: icon, actions: actions, style: style)
                    .environmentObject(Theme.sharedTheme)
            }
        } else {
            return HostingConfiguration {
                EmptyStateView(title: title, message: message, icon: icon, actions: actions, style: style)
                    .environmentObject(Theme.sharedTheme)
            }
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
