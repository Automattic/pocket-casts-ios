import SwiftUI

struct KidsProfileBannerView: View {
    @EnvironmentObject var theme: Theme

    let viewModel: KidsProfileBannerViewModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.primaryUi01Active)

            HStack {
                textsView
                    .padding(.leading, 16)
                    .padding(.trailing, 35)

                Spacer()

                ZStack(alignment: .topTrailing) {
                    VStack {
                        Spacer()

                        Image("kids-profile-banner-face")
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack {
                        Button(action: viewModel.closeButtonTap) {
                            Image(systemName: "xmark")
                                .imageScale(.small)
                                .foregroundColor(theme.secondaryIcon02)
                        }
                        .frame(width: 24, height: 24)
                        .padding(.top, 8)
                        .padding(.trailing, 4)

                        Spacer()
                    }
                }
            }
        }
        .frame(height: 105)
    }

    var textsView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(L10n.kidsProfileBannerTitle)
                    .font(
                        Font.custom("SF Pro Text", size: 15.0)
                            .weight(.semibold)
                    )
                    .frame(alignment: .topLeading)
                    .foregroundStyle(theme.primaryText01)

                Text(L10n.kidsProfileBannerBadge)
                    .font(
                        Font.custom("SF Pro Text", size: 11)
                            .weight(.semibold)
                    )
                    .foregroundColor(theme.secondaryText02)
                    .opacity(0.8)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.primaryUi05)
                    .cornerRadius(4)
            }

            Text(L10n.kidsProfileBannerText)
                .font(
                    Font.custom("SF Pro Text", size: 11)
                        .weight(.semibold)
                )
                .foregroundColor(theme.secondaryText02)
                .opacity(0.8)
                .padding(.bottom, 4)

            Button(action: viewModel.requestEarlyAccessTap) {
                Text(L10n.kidsProfileBannerRequestButton)
                    .font(
                        Font.custom("SF Pro Text", size: 11)
                            .weight(.semibold)
                    )
                    .foregroundStyle(theme.primaryInteractive01)
                    .opacity(0.8)
            }
        }
    }
}

struct KidsProfileBannerViewLight_Preview: PreviewProvider {
    static var previews: some View {
        KidsProfileBannerView(viewModel: KidsProfileBannerViewModel())
            .environmentObject(Theme(previewTheme: .light))
            .previewLayout(.sizeThatFits)
            .padding(16)
    }
}

struct KidsProfileBannerViewDark_Preview: PreviewProvider {
    static var previews: some View {
        KidsProfileBannerView(viewModel: KidsProfileBannerViewModel())
            .environmentObject(Theme(previewTheme: .dark))
            .previewLayout(.sizeThatFits)
            .padding(16)
    }
}
