import SwiftUI
import Kingfisher

/// Shows the default profile image view and attempts to load the gravatar using the email
struct ProfileImage: View {
    @EnvironmentObject var theme: Theme
    let email: String?

    var body: some View {
        if let url {
            KFImage
                .url(url, cacheKey: email)
                .startLoadingBeforeViewAppear()
                .cancelOnDisappear(true)
                .placeholder { _ in defaultProfileView }
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            defaultProfileView
        }
    }

    private var url: URL? {
        email.flatMap { URL(string: "https://www.gravatar.com/avatar/\($0.md5)?d=404&s=\(256)") }
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
