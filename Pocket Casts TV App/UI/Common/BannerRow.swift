import SwiftUI

enum BannerType {
    case createAccount
    case discoverMore

    var title: String {
        switch self {
        case .createAccount:
            return L10n.tvBannerCreateAccountTitle
        case .discoverMore:
            return L10n.tvBannerDiscoverMoreTitle
        }
    }

    var subtitle: String {
        switch self {
        case .createAccount:
            return L10n.tvBannerCreateAccountSubtitle
        case .discoverMore:
            return L10n.tvBannerDiscoverMoreSubtitle
        }
    }

    var actionTitle: String {
        switch self {
        case .createAccount:
            return L10n.tvBannerCreateAccountActionTitle
        case .discoverMore:
            return L10n.tvBannerDiscoverMoreActionTitle
        }
    }

    var icon: ImageResource {
        switch self {
        case .createAccount:
            return ImageResource.Banners.createAccount
        case .discoverMore:
            return ImageResource.Banners.discoverMore
        }
    }
}

struct BannerRow: View {

    let title: String
    let subtitle: String
    let actionTitle: String
    let icon: ImageResource
    let action: (() -> ())?

    init(type: BannerType, action: (() -> ())? = nil) {
        self.title = type.title
        self.subtitle = type.subtitle
        self.actionTitle = type.actionTitle
        self.icon = type.icon
        self.action = action
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Image(icon)
            HStack(spacing: 0) {
                Spacer().frame(width: 400)
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    Text(subtitle)
                        .font(.headline)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Button() {
                    action?()
                } label: {
                    Text(actionTitle)
                        .font(.caption2)
                }
                Spacer()
                    .frame(width: 72)
            }
        }
        .background(Color.backgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .focusSection()
    }
}

#Preview {
    BannerRow(type: .createAccount)
    BannerRow(type: .discoverMore)
}
