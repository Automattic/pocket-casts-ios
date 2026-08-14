import PocketCastsServer
import PocketCastsUtils
import SwiftUI

struct AboutView: View {
    private let minLogoSize: CGFloat = 45
    private let maxLogoSize: CGFloat = 80
    private let logoOffsetAmount: CGFloat = 42
    private let familyCellTopPadding: CGFloat = 6

    /// Tall enough to fit the staggered logos (which extend `logoOffsetAmount` above and below their base
    /// size) plus headroom for the idle float and scroll reaction, so they don't visibly clip. The row
    /// re-centers its content within this extra headroom (see `FamilyLogosRow`), so it must be added
    /// symmetrically here rather than just growing the frame, or the extra space collapses to one side.
    private var logoCellHeight: CGFloat { maxLogoSize + 2 * logoOffsetAmount + 2 * familyMotionBuffer }
    private let familyMotionBuffer: CGFloat = 20

    @EnvironmentObject var theme: Theme

    @StateObject private var model = AboutViewModel()

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack(path: $model.navigationPath) {
            ZStack {
                ThemeColor.primaryUi04(for: theme.activeTheme).color
                    .ignoresSafeArea()
                Form {
                    form
                }
                .colorScheme(theme.activeTheme.isDark ? .dark : .light)
                .scrollContentBackground(.hidden)
            }
            .navigationDestination(for: AboutNavigationPathComponent.self) {
                switch $0 {
                case .legalAndMore:
                    LegalAndMoreView(navigationPath: $model.navigationPath)
                case .termsOfService:
                    WebView(url: LegalAndMoreView.Constants.termsOfUseURL)
                        .navigationTitle(L10n.aboutTermsOfService)
                        .ignoresSafeArea()
                case .privacyPolicy:
                    WebView(url: LegalAndMoreView.Constants.privacyPolicyURL)
                        .navigationTitle(L10n.aboutPrivacyPolicy)
                        .ignoresSafeArea()
                case .acknowledgements:
                    WebView(url: LegalAndMoreView.Constants.acknowledgementsURL)
                        .navigationTitle(L10n.aboutAcknowledgements)
                        .ignoresSafeArea()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button.make(role: .close) {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var form: some View {
        VStack {
            Image(AppTheme.pcLogoVerticalImageName())
                .accessibilityHidden(true)
            Text(Settings.displayableVersion())
                .font(.subheadline)
                .textStyle(SecondaryText())
                .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)

        if model.shouldShowWhatsNew, let whatsNewInfo = model.whatsNewInfo {
            Section {
                AboutRow(mainText: model.whatsNewText) {
                    NavigationManager.sharedManager.navigateTo(NavigationManager.showWhatsNewPageKey, data: [NavigationManager.whatsNewInfoKey: whatsNewInfo])
                }
            }
        }

        Section {
            AboutRow(mainText: L10n.aboutRateUs) {
                model.track(action: .rateUs)
                openUrl(ServerConstants.Urls.appStoreReview)
            }
            AboutRow(mainText: L10n.aboutShareFriends) {
                model.track(action: .shareWithFriends)
                openShareApp()
            }
        }

        Section {
            AboutRow(mainText: L10n.aboutWebsite, secondaryText: L10n.websiteShort) {
                model.track(action: .website)
                openUrl(ServerConstants.Urls.pocketcastsDotCom)
            }
            AboutRow(mainText: L10n.instagram, secondaryText: L10n.socialHandle) {
                model.track(action: .instagram)
                SocialsHelper.openInstagram()
            }
            AboutRow(mainText: L10n.xCom, secondaryText: L10n.socialHandle) {
                model.track(action: .twitter)
                SocialsHelper.openTwitter()
            }
        }

        Section {
            AboutRow(mainText: L10n.aboutLegalAndMore, showChevronIcon: true) {
                model.navigationPath = [.legalAndMore]
            }
        }

        Section {
            VStack(alignment: .leading) {
                Text(L10n.aboutA8cFamily)
                    .textStyle(PrimaryText())
                    .fixedSize(horizontal: false, vertical: true)
                FamilyLogosRow(
                    minLogoSize: minLogoSize,
                    maxLogoSize: maxLogoSize,
                    logoOffsetAmount: logoOffsetAmount,
                    logoCellHeight: logoCellHeight,
                    motionBuffer: familyMotionBuffer
                )
            }
            .padding(.top, familyCellTopPadding)
            .onTapGesture {
                model.track(action: .automatticFamily)
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
                model.track(action: .workWithUs)
                openUrl(ServerConstants.Urls.automatticWorkWithUs)
            }
        }
        .listRowBackground(ThemeColor.primaryUi02(for: theme.activeTheme).color)

        Section {
            HStack {
                Spacer()
                Image("automattic-logo")
                    .tint(theme.activeTheme.isDark ? .white : .black)
                Spacer()
            }
        }
        .listRowBackground(Color.clear)
    }


    private func openShareApp() {
        guard let controller = SceneHelper.rootViewController() else { return }

        SharingHelper.shared.shareLinkToApp(fromController: controller)
    }

    private func openUrl(_ urlStr: String) {
        guard let url = URL(string: urlStr) else { return }

        let application = UIApplication.shared
        if application.canOpenURL(url) {
            application.open(url, options: [:], completionHandler: nil)
        }
    }
}

/// Renders the row of Automattic family logos, drifting gently on their own like they're suspended in water.
struct FamilyLogosRow: View {
    let minLogoSize: CGFloat
    let maxLogoSize: CGFloat
    let logoOffsetAmount: CGFloat
    let logoCellHeight: CGFloat
    let motionBuffer: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let logoSize = calculateLogoSize(geometry: geometry)
            HStack(alignment: .bottom) {
                ForEach(Array(AboutLogo.allCases.enumerated()), id: \.element) { index, logo in
                    LogoView(logo: logo, index: index, logoSize: logoSize, logoOffset: logoOffsetAmount)
                }
            }
            .padding(.top, logoOffsetAmount + motionBuffer)
        }
        .frame(height: logoCellHeight)
        .clipped()
    }

    private func calculateLogoSize(geometry: GeometryProxy) -> CGFloat {
        let sizeToFit = geometry.size.width / CGFloat(AboutLogo.allCases.count) * 1.4

        return sizeToFit.clamped(to: minLogoSize ..< maxLogoSize)
    }
}

struct LogoView: View {
    @EnvironmentObject var theme: Theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let maxRotationDegrees: Double = 30

    var logo: AboutLogo
    var index: Int
    var logoSize: CGFloat
    var logoOffset: CGFloat

    @State private var baseRotation: Angle

    init(logo: AboutLogo, index: Int, logoSize: CGFloat, logoOffset: CGFloat) {
        self.logo = logo
        self.index = index
        self.logoSize = logoSize
        self.logoOffset = logoOffset
        _baseRotation = State(initialValue: logo.randomRotation(maxDegrees: Self.maxRotationDegrees))
    }

    /// Idle bobbing motion so the logos drift a little even at rest, like they're suspended in water.
    private var floatFrequency: Double { 0.45 + Double(index) * 0.11 }
    private var floatAmplitude: CGFloat { 3 + CGFloat(index % 3) }
    private var floatPhase: Double { Double(index) * 1.7 }

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let floatOffset: CGFloat = reduceMotion ? 0 : CGFloat(sin(time * floatFrequency + floatPhase)) * floatAmplitude
            let floatRotation: Double = reduceMotion ? 0 : sin(time * floatFrequency * 0.6 + floatPhase) * 3

            ZStack {
                Circle()
                    .foregroundColor(logo.color)
                Image(logo.logoName)
                    .rotationEffect(baseRotation + .degrees(floatRotation))
                    .tint(logo.logoTint(onDark: theme.activeTheme.isDark))
            }
            .offset(
                x: -logoOffset * CGFloat(index),
                y: (index % 2 == 0 ? -logoOffset : logoOffset) + floatOffset
            )
            .frame(width: logoSize, height: logoSize)
            .accessibilityLabel(logo.description)
        }
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
                if let secondaryText {
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
        AboutView()
            .environmentObject(Theme(previewTheme: .dark))
    }
}
