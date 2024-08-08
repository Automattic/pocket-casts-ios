import SwiftUI

struct KidsProfileBannerView: View {
    @EnvironmentObject var theme: Theme

    let viewModel: KidsProfileBannerViewModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.cornerRadiusBig)
                .fill(theme.primaryUi02Active)

            HStack {
                textsView
                    .padding(.leading, Constants.textsViewPaddingLeading)
                    .padding(.trailing, Constants.textsViewPaddingTrailing)

                Spacer()

                ZStack(alignment: .topTrailing) {
                    VStack {
                        Spacer()

                        Image("kids-profile-banner-face")
                            .clipShape(
                                PCUnevenRoundedRectangle(topLeadingRadius: 0,
                                                         bottomLeadingRadius: 0,
                                                         bottomTrailingRadius: Constants.cornerRadiusBig,
                                                         topTrailingRadius: 0)
                            )
                    }

                    VStack {
                        Button(action: viewModel.closeButtonTap) {
                            Image(systemName: "xmark")
                                .imageScale(.small)
                                .foregroundStyle(theme.secondaryIcon02)
                        }
                        .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                        .padding(.top, Constants.buttonPaddingTop)
                        .padding(.trailing, Constants.buttonPaddingTrailing)

                        Spacer()
                    }
                }
            }
        }
        .frame(minHeight: Constants.minHeight)
    }

    var textsView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(L10n.kidsProfileBannerTitle)
                    .font(size: Constants.titleSize, style: .body, weight: .semibold)
                    .frame(alignment: .topLeading)
                    .foregroundStyle(theme.primaryText01)

                badge
            }

            Text(L10n.kidsProfileBannerText)
                .font(size: Constants.textSize, style: .body, weight: .medium)
                .foregroundColor(theme.primaryText02)
                .opacity(Constants.opacity)
                .padding(.bottom, Constants.textPaddingBottom)

            Button(action: viewModel.requestEarlyAccessTap) {
                Text(L10n.kidsProfileBannerRequestButton)
                    .font(size: Constants.buttonTitleSize, style: .body, weight: .medium)
                    .foregroundStyle(theme.primaryInteractive01)
                    .opacity(Constants.opacity)
            }
            .buttonStyle(.plain)
        }
    }

    private var badge: some View {
        HStack {
            Text(L10n.kidsProfileBannerBadge)
                .font(size: Constants.textSize, style: .body, weight: .medium)
                .foregroundStyle(theme.primaryInteractive02)
                .opacity(Constants.opacity)
        }
        .padding(.horizontal, Constants.badgePaddingH)
        .padding(.vertical, Constants.badgePaddingV)
        .background(theme.primaryInteractive01)
        .cornerRadius(Constants.cornerRadiusSmall)
    }

    private enum Constants {
        static let opacity = 0.8
        static let titleSize = 15.0
        static let textSize = 11.0
        static let buttonTitleSize = 13.0

        static let minHeight = 105.0
        static let buttonSize = 24.0
        static let cornerRadiusBig = 8.0
        static let cornerRadiusSmall = 4.0

        static let badgePaddingH = 6.0
        static let badgePaddingV = 2.0

        static let textPaddingBottom = 4.0

        static let buttonPaddingTrailing = 4.0
        static let buttonPaddingTop = 8.0

        static let textsViewPaddingTrailing = 35.0
        static let textsViewPaddingLeading = 16.0
    }
}

struct KidsProfileBannerViewLight_Preview: PreviewProvider {
    static var previews: some View {
        KidsProfileBannerView(viewModel: KidsProfileBannerViewModel())
            .environmentObject(Theme(previewTheme: .light))
            .previewLayout(.sizeThatFits)
            .padding(16)
            .frame(height: 105)
    }
}

struct KidsProfileBannerViewDark_Preview: PreviewProvider {
    static var previews: some View {
        KidsProfileBannerView(viewModel: KidsProfileBannerViewModel())
            .environmentObject(Theme(previewTheme: .dark))
            .previewLayout(.sizeThatFits)
            .padding(16)
            .frame(height: 105)
    }
}
