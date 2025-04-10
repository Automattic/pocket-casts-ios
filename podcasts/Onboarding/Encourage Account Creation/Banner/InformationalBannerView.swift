import SwiftUI

struct InformationalBannerView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var viewModel: InformationalBannerViewModel

    private var backgroundColor: Color {
        if case .profile = viewModel.bannerType {
            return theme.primaryUi02Active
        }
        return theme.primaryUi01
    }

    var body: some View {
        HStack(alignment: .top) {
            Image(viewModel.bannerType.iconName)
                .foregroundColor(theme.primaryText01)
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.bannerType.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.primaryText01)
                Text(viewModel.bannerType.description)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 14))
                    .foregroundColor(theme.primaryText02)
                Button() {
                    viewModel.onCreateFreeAccountTap?()
                } label: {
                    Text(L10n.eacInformationalBannerCreateAccount)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.primaryText02Selected)
                }
                .padding(.top, 6.0)
            }
            Spacer()
        }
        .padding(.top, 20.0)
        .padding(.leading, 16.0)
        .padding(.trailing, 56.0)
        .padding(.bottom, 20.0)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(alignment: .topTrailing) {
            Button() {
                viewModel.onCloseBannerTap?()
            } label: {
                Image("close")
                    .renderingMode(.template)
                    .foregroundColor(theme.primaryText01)
            }
            .padding(.top, 16.0)
            .padding(.trailing, 16.0)
        }
        .padding(16.0)
    }
}

struct InformationalBannerViewFilters_Preview: PreviewProvider {
    static var previews: some View {
        VStack {
            Group {
                InformationalBannerView(viewModel: InformationalBannerViewModel(bannerType: .filters))
                    .environmentObject(Theme(previewTheme: .light))
                    .previewLayout(.sizeThatFits)
                    .frame(width: 386, height: 170)

                InformationalBannerView(viewModel: InformationalBannerViewModel(bannerType: .listeningHistory))
                    .environmentObject(Theme(previewTheme: .light))
                    .previewLayout(.sizeThatFits)
                    .frame(width: 386, height: 170)
            }
            .background(.gray.opacity(0.5))

            InformationalBannerView(viewModel: InformationalBannerViewModel(bannerType: .profile))
                .environmentObject(Theme(previewTheme: .light))
                .previewLayout(.sizeThatFits)
                .frame(width: 386, height: 170)
        }
    }
}
