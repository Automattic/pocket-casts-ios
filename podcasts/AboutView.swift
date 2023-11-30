import PocketCastsServer
import PocketCastsUtils
import SwiftUI

struct AboutView: View {
    private let logoCellHeight: CGFloat = 120
    private let familyCellHeight: CGFloat = 160
    private let logoOffsetAmount: CGFloat = 30
    private let familyCellTopPadding: CGFloat = 6

    @EnvironmentObject var theme: Theme

    @ObservedObject private var model = AboutViewModel()

    @State private var showLegalAndMore = false

    var dismissAction: () -> Void

    init(dismissAction: @escaping (() -> Void)) {
        self.dismissAction = dismissAction
    }

    var body: some View {
        NavigationView {
            ZStack {
                ThemeColor.primaryUi04(for: theme.activeTheme).color
                    .ignoresSafeArea()
                VStack {
                    VStack {
                        ModalCloseButton(action: dismissAction)
                        Image(AppTheme.pcLogoVerticalImageName())
                            .accessibilityHidden(true)
                        Text(Settings.displayableVersion())
                            .font(.subheadline)
                            .textStyle(SecondaryText())
                            .padding(.top, 5)
                    }
                    .padding(.top, 30)
                    Form {
                        if model.shouldShowWhatsNew, let whatsNewInfo = model.whatsNewInfo {
                            Section {
                                AboutRow(mainText: model.whatsNewText) {
                                    NavigationManager.sharedManager.navigateTo(NavigationManager.showWhatsNewPageKey, data: [NavigationManager.whatsNewInfoKey: whatsNewInfo])
                                }
                            }
                        }
                        Section {
                            AboutRow(mainText: L10n.aboutRateUs) {
                                openUrl(ServerConstants.Urls.appStoreReview)
                            }
                            AboutRow(mainText: L10n.aboutShareFriends) {
                                openShareApp()
                            }
                        }
                        Section {
                            AboutRow(mainText: L10n.aboutWebsite, secondaryText: L10n.websiteShort) {
                                openUrl(ServerConstants.Urls.pocketcastsDotCom)
                            }
                            AboutRow(mainText: L10n.instagram, secondaryText: L10n.socialHandle) {
                                SocialsHelper.openInstagram()
                            }
                            AboutRow(mainText: L10n.twitter, secondaryText: L10n.socialHandle) {
                                SocialsHelper.openTwitter()
                            }
                        }
                        Section {
                            AboutRow(mainText: L10n.aboutLegalAndMore, showChevronIcon: true) {
                                showLegalAndMore = true
                            }
                        }
                        Section {
                            VStack(alignment: .leading) {
                                Text(L10n.aboutA8cFamily)
                                    .textStyle(PrimaryText())
                                    .padding(.top, familyCellTopPadding)
                                GeometryReader { geometry in
                                    HStack(alignment: .bottom) {
                                        ForEach(Array(AboutLogo.allCases.enumerated()), id: \.element) { index, logo in
                                            LogoView(logo: logo, index: index, logoSize: calculateLogoSize(geometry: geometry), logoOffset: logoOffsetAmount)
                                        }
                                    }
                                    .offset(y: logoCellHeight - logoOffsetAmount - calculateLogoSize(geometry: geometry) + familyCellTopPadding)
                                }
                                .frame(height: logoCellHeight)
                            }
                            .frame(height: familyCellHeight)
                            .onTapGesture {
                                openUrl(ServerConstants.Urls.automatticDotCom)
                            }
                        }
                        .listRowBackground(ThemeColor.primaryUi02(for: theme.activeTheme).color)
                        Section {
                            VStack(alignment: .leading) {
                                Text(L10n.aboutWorkWithUs)
                                    .textStyle(PrimaryText())
                                Text(L10n.aboutJoinFromAnywhere)
                                    .textStyle(SecondaryText())
                                    .font(.subheadline)
                            }
                            .onTapGesture {
                                openUrl(ServerConstants.Urls.automatticWorkWithUs)
                            }
                        }
                        .listRowBackground(ThemeColor.primaryUi02(for: theme.activeTheme).color)
                    }
                    .colorScheme(theme.activeTheme.isDark ? .dark : .light)
                }
                NavigationLink(destination: LegalAndMore(), isActive: $showLegalAndMore) {}
            }
            .navigationBarHidden(true)
        }.navigationViewStyle(StackNavigationViewStyle())
    }

    private func openShareApp() {
        guard let controller = SceneHelper.rootViewController() else { return }

        SharingHelper.shared.shareLinkToApp(fromController: controller)
    }

    private func calculateLogoSize(geometry: GeometryProxy) -> CGFloat {
        let sizeToFit = geometry.size.width / CGFloat(AboutLogo.allCases.count) * 1.4

        return sizeToFit.clamped(to: 45 ..< 80)
    }

    private func openUrl(_ urlStr: String) {
        guard let url = URL(string: urlStr) else { return }

        let application = UIApplication.shared
        if application.canOpenURL(url) {
            application.open(url, options: [:], completionHandler: nil)
        }
    }
}

struct LogoView: View {
    @EnvironmentObject var theme: Theme

    private let maxRotationDegrees: Double = 30

    var logo: AboutLogo
    var index: Int
    var logoSize: CGFloat
    var logoOffset: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(logo.color)
            Image(logo.logoName)
                .rotationEffect(logo.randomRotation(maxDegrees: maxRotationDegrees))
                .tint(logo.logoTint(onDark: theme.activeTheme.isDark))
        }
        .offset(x: -logoOffset * CGFloat(index), y: index % 2 == 0 ? -logoOffset : logoOffset)
        .frame(width: logoSize, height: logoSize)
        .accessibilityLabel(logo.description)
    }
}

struct AboutRow: View {
    @EnvironmentObject var theme: Theme

    @State var mainText = ""
    @State var secondaryText: String? = nil
    @State var showChevronIcon: Bool = false
    @State var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                Text(mainText)
                    .textStyle(PrimaryText())
                Spacer()
                if let secondaryText = secondaryText {
                    Text(secondaryText)
                        .textStyle(SecondaryText())
                }
                if showChevronIcon {
                    Image("chevron")
                        .renderingMode(.template)
                        .foregroundColor(ThemeColor.primaryIcon02(for: theme.activeTheme).color)
                }
            }
        }
        .listRowBackground(ThemeColor.primaryUi02(for: theme.activeTheme).color)
    }
}

// MARK: Previews

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView {}
            .environmentObject(Theme(previewTheme: .dark))
    }
}
