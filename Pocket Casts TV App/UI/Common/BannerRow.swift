import SwiftUI

enum BannerType: String {
    case createAccount = "create_account"
    case discoverMore = "discover_more"

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
        ZStack(alignment: .trailing) {
            Image(icon)
                .accessibilityHidden(true)
            if gradient {
                // Solid dark on the left (where the CTA + text sit), fading to clear
                // over the rightmost 18% so the artwork on the right blends into the
                // dark surface instead of butting up against a hard edge.
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color.pcBackgroundSunken, location: 0.00),
                        Gradient.Stop(color: Color.pcBackgroundSunken.opacity(0), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 0.82, y: 0.5),
                    endPoint: UnitPoint(x: 1.0, y: 0.5)
                )
            }
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 72)
                Button() {
                    action?()
                } label: {
                    Text(actionTitle)
                        .font(.caption2)
                }
                .disabled(action == nil)
                .setFocus(section: focusSection)
                .accessibilityLabel("\(title). \(subtitle). \(actionTitle)")
                Spacer().frame(width: 80)
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.pcTextPrimary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.headline)
                        .foregroundStyle(Color.pcTextSecondary)
                        .lineLimit(2)
                }
                .accessibilityHidden(true)
                Spacer()
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
