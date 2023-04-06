import SwiftUI

struct UpgradeLandingView: View {
    var body: some View {
        ZStack {

            LinearGradient(gradient: Gradient(colors: [Color(hex: "121212"), Color(hex: "121212"), Color(hex: "D4B43A"), Color(hex: "FFDE64")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollViewIfNeeded {
                VStack(spacing: 0) {
                    PlusLabel(L10n.plusMarketingTitle, for: .title2)
                        .padding(.bottom, 16)
                        .padding(.horizontal, 32)

                    UpgradeRoundedSegmentedControl()
                        .padding(.bottom, 24)

                    VStack() {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 4) {
                                Image("plusGold")
                                    .padding(.leading, 8)
                                Text("Plus")
                                    .foregroundColor(.white)
                                    .font(style: .subheadline, weight: .medium)
                                    .padding(.trailing, 8)
                                    .padding(.top, 2)
                                    .padding(.bottom, 2)
                            }
                            .background(.black)
                            .cornerRadius(800)
                            .padding(.bottom, 10)

                            HStack() {
                                Text("$39.99")
                                    .font(style: .largeTitle, weight: .bold)
                                Text("/\(L10n.year)")
                                    .font(style: .headline, weight: .bold)
                                    .opacity(0.6)
                                    .padding(.top, 6)
                            }
                            .padding(.bottom, 8)

                            Text(L10n.accountDetailsPlusTitle)
                                .font(style: .caption2, weight: .semibold)
                                .opacity(0.64)
                                .padding(.bottom, 16)

                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 16) {
                                    Image("plus-feature-desktop")
                                        .renderingMode(.template)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.black)
                                        .frame(width: 16, height: 16)
                                    Text(L10n.plusMarketingDesktopAppsTitle)
                                        .font(size: 14, style: .subheadline, weight: .medium)
                                }
                                HStack(spacing: 16) {
                                    Image("plus-feature-folders")
                                        .renderingMode(.template)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.black)
                                        .frame(width: 16, height: 16)
                                    Text(L10n.folders)
                                        .font(size: 14, style: .subheadline, weight: .medium)
                                }
                                HStack(spacing: 16) {
                                    Image("plus-feature-cloud")
                                        .renderingMode(.template)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.black)
                                        .frame(width: 16, height: 16)
                                    Text(L10n.plusCloudStorageLimitFormat(10))
                                        .font(size: 14, style: .subheadline, weight: .medium)
                                }
                                HStack(spacing: 16) {
                                    Image("plus-feature-watch")
                                        .renderingMode(.template)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.black)
                                        .frame(width: 16, height: 16)
                                    Text(L10n.plusMarketingWatchPlaybackTitle)
                                        .font(size: 14, style: .subheadline, weight: .medium)
                                }
                                HStack(spacing: 16) {
                                    Image("plus-feature-extra")
                                        .renderingMode(.template)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.black)
                                        .frame(width: 16, height: 16)
                                    Text(L10n.plusFeatureThemesIcons)
                                        .font(size: 14, style: .subheadline, weight: .medium)
                                }
                                HStack(alignment: .top, spacing: 16) {
                                    Image("plus-feature-love")
                                        .renderingMode(.template)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.black)
                                        .frame(width: 16, height: 16)
                                    Text(L10n.plusFeatureGratitude)
                                        .font(size: 14, style: .subheadline, weight: .medium)
                                }
                            }
                            .padding(.bottom, 24)

                            Button("Subscribe to Plus") {

                            }
                            .buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, background: Color(hex: "FFD846")))
                        }
                        .padding(.all, 24)

                    }
                    .background(.white)
                    .cornerRadius(24)
                    .padding(.leading, 40)
                    .padding(.trailing, 40)
                    .shadow(color: .black.opacity(0.01), radius: 10, x: 0, y: 24)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 14)
                    .shadow(color: .black.opacity(0.09), radius: 6, x: 0, y: 6)
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .shadow(color: .black.opacity(0.1), radius: 0, x: 0, y: 0)
                }
            }
        }
    }
}

struct UpgradeRoundedSegmentedControl: View {
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Text(L10n.yearly)
                    .font(style: .subheadline, weight: .medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .background(.white)
            .cornerRadius(24)
            .padding(.all, 4)

            ZStack {
                Text(L10n.monthly)
                    .font(style: .subheadline, weight: .medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .cornerRadius(24)
            .padding(.all, 4)
        }
        .background(.white.opacity(0.16))
        .cornerRadius(24)
    }
}

struct UpgradeLandingView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradeLandingView()
    }
}
