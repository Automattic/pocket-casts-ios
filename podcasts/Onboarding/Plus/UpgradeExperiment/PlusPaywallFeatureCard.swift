import SwiftUI

enum FeatureCardItem: String, CaseIterable, Identifiable {
    case desktop
    case folders
    case bookmarks
    case wearOs
    case slumberStudio
    case storage
    case extraThemes

    var id: Self {
        return self
    }

    var title: String {
        switch self {
        case .desktop:
            return L10n.plusFeatureCardTitleDesktop
        case .folders:
            return L10n.plusFeatureCardTitleFolders
        case .bookmarks:
            return L10n.plusFeatureCardTitleBookmarks
        case .wearOs:
            return L10n.plusFeatureCardTitleWearOs
        case .slumberStudio:
            return L10n.plusFeatureCardTitleSlumberStudio
        case .storage:
            return L10n.plusFeatureCardTitleStorage
        case .extraThemes:
            return L10n.plusFeatureCardTitleExtraThemes
        }
    }

    var text: String {
        switch self {
        case .desktop:
            return L10n.plusFeatureCardTextDesktop
        case .folders:
            return L10n.plusFeatureCardTextFolders
        case .bookmarks:
            return L10n.plusFeatureCardTextBookmarks
        case .wearOs:
            return L10n.plusFeatureCardTextWearOs
        case .slumberStudio:
            return L10n.plusFeatureCardTextSlumberStudio
        case .storage:
            return L10n.plusFeatureCardTextStorage
        case .extraThemes:
            return L10n.plusFeatureCardTextExtraThemes
        }
    }

    var image: String {
        return "plus_feature_card_\(rawValue.lowerSnakeCased())"
    }
}

struct PlusPaywallFeatureCard: View {
    let item: FeatureCardItem

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(Constants.backgroundColor)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    Image(item.image)
                        .frame(width: Constants.imageSize.width,
                               height: Constants.imageSize.height)
                    Spacer()
                }
                text(item.title,
                     size: Constants.titleSize,
                     weight: .semibold,
                     lineLimit: Constants.titleLineLimit)
                text(item.text,
                     size: Constants.textSize,
                     weight: .regular,
                     lineLimit: Constants.textLineLimit)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func text(_ text: String, size: Double, weight: Font.Weight, lineLimit: Int) -> some View {
        Text(text)
            .font(size: size, style: .body, weight: weight)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            .lineLimit(lineLimit)
            .padding(.horizontal, 24.0)
    }

    enum Constants {
        static let backgroundColor = Color(hex: "#161718")

        static let cornerRadius = 10.0

        static let imageSize = CGSizeMake(300, 294)

        static let titleSize = 18.0
        static let titleLineLimit = 2

        static let textSize = 14.0
        static let textLineLimit = 3
    }
}

#Preview {
    PlusPaywallFeatureCard(item: .wearOs)
        .frame(width: 313, height: 394)
}
