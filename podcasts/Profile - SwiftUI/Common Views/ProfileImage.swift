import SwiftUI
import Kingfisher

/// Shows the default profile image view and attempts to load the gravatar using the email
struct ProfileImage: View {
    @EnvironmentObject var theme: Theme
    let email: String?
    private let avatarRefreshPublisher = NotificationCenter.default.publisher(for: Constants.Notifications.avatarNeedsRefreshing)
    @State private var forceRefresh: Bool = false
    @State private var reloadId = UUID()

    var body: some View {
        ZStack {
            if let url {
                KFImage
                    .url(url, cacheKey: email)
                    .placeholder { _ in defaultProfileView }
                    .resizable()
                    .forceRefresh(forceRefresh)
                    .onSuccess { result in
                        forceRefresh = false
                    }
                    .aspectRatio(contentMode: .fill)
            } else {
                defaultProfileView
            }
        }.onReceive(avatarRefreshPublisher, perform: { _ in
            forceRefresh = true
            reloadId = UUID() // updating forceRefresh alone doesn't work for reloading the KFImage
        })
        .id(reloadId)
    }

    private var url: URL? {
        forceRefresh ? cacheBusterURL : defaultURL
    }

    private var defaultURL: URL? {
        urlString.flatMap { URL(string: $0) }
    }

    /// We add a random query parameter to bypass the backend cache and get the latest image.
    private var cacheBusterURL: URL? {
        urlString.flatMap { URL(string: "\($0)&_=\(Int(NSDate().timeIntervalSince1970))") }
    }

    private var urlString: String? {
        email.flatMap { "https://www.gravatar.com/avatar/\($0.sha256)?d=404&s=\(256)" }
    }

    private var defaultProfileView: some View {
        ZStack {
            theme.primaryUi05

            Image("profileAvatar")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .foregroundColor(theme.primaryUi01)
                .padding()
        }
    }
}
