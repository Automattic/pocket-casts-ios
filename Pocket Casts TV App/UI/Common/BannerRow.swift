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

    var gradient: Bool {
        switch self {
        case .createAccount:
            return false
        case .discoverMore:
            return true
        }
    }
}

struct BannerRow: View {

    let title: String
    let subtitle: String
    let actionTitle: String
    let icon: ImageResource
    let gradient: Bool
    let action: (() -> ())?

    let focusSection: String

    init(type: BannerType, focusSection: String = "BannerRow", action: (() -> ())? = nil) {
        self.title = type.title
        self.subtitle = type.subtitle
        self.actionTitle = type.actionTitle
        self.icon = type.icon
        self.gradient = type.gradient
        self.action = action
        self.focusSection = focusSection
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Image(icon)
            if gradient {
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color.pcBackgroundSunken.opacity(0), location: 0.00),
                        Gradient.Stop(color: Color.pcBackgroundSunken, location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 0, y: 0.5),
                    endPoint: UnitPoint(x: 0.18, y: 0.5)
                )
            }
            HStack(spacing: 0) {
                Spacer().frame(width: 400)
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.pcTextPrimary)
                    Text(subtitle)
                        .font(.headline)
                        .foregroundStyle(Color.pcTextSecondary)
                }
                Spacer()
                Button() {
                    action?()
                } label: {
                    Text(actionTitle)
                        .font(.caption2)
                }
                .disabled(action == nil)
                .setFocus(section: focusSection)
                Spacer()
                    .frame(width: 72)
            }
        }
        .background(Color.pcBackgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .focusSection()
    }
}

#Preview {
    BannerRow(type: .createAccount)
    BannerRow(type: .discoverMore)
}
