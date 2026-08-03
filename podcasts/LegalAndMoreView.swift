import SwiftUI

struct LegalAndMoreView: View {
    @EnvironmentObject var theme: Theme

    @Binding var navigationPath: [AboutNavigationPathComponent]

    var body: some View {
        ZStack {
            ThemeColor.primaryUi04(for: theme.activeTheme).color
                .ignoresSafeArea()
            List {
                Section {
                    AboutRow(mainText: L10n.aboutTermsOfService, showChevronIcon: true) {
                        track(row: "terms_of_service")
                        navigationPath.append(.termsOfService)
                    }
                    AboutRow(mainText: L10n.aboutPrivacyPolicy, showChevronIcon: true) {
                        track(row: "privacy_policy")
                        navigationPath.append(.privacyPolicy)
                    }
                    AboutRow(mainText: L10n.aboutAcknowledgements, showChevronIcon: true) {
                        track(row: "acknowledgements")
                        navigationPath.append(.acknowledgements)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .colorScheme(theme.activeTheme.isDark ? .dark : .light)
            .scrollContentBackground(.hidden)
        }
        .navigationBarTitle(L10n.aboutLegalAndMore, displayMode: .inline)
    }

    private func track(row: String) {
        Analytics.track(.settingsAboutLegalAndMoreTapped, properties: ["row": row])
    }

    enum Constants {
        static let termsOfUseURL = URL(string: "https://support.pocketcasts.com/article/terms-of-use-overview/")!
        static let privacyPolicyURL = URL(string: "https://support.pocketcasts.com/article/privacy-policy/")!
        static let acknowledgementsURL = Bundle.main.url(forResource: "acknowledgements", withExtension: "html")!
    }
}

struct WebView: UIViewControllerRepresentable {
    var url: URL

    func makeUIViewController(context: Context) -> OnlineSupportController {
        OnlineSupportController(url: url, source: .about)
    }

    func updateUIViewController(_ uiViewController: OnlineSupportController, context: Context) {}
}
