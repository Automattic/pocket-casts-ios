import Combine
import SwiftUI
import PocketCastsUtils
import PocketCastsServer

class NotificationsPermissionsViewModel: ObservableObject {
    @Published private(set) var newsletterOptIn: Bool
    @Published var notificationsOptIn: Bool = true

    /// Only ask to subscribe when there's an account to attach the newsletter to.
    let showNewsletterOptIn = SyncManager.isUserLoggedIn()

    /// A new account is offered the newsletter ticked. An account that already existed has its
    /// own setting, so the screen shows that and leaves it alone unless the user changes it here.
    private let isNewAccount: Bool
    private var didChangeNewsletterOptIn = false
    private var syncObserver: AnyCancellable?

    init(isNewAccount: Bool = false) {
        self.isNewAccount = isNewAccount
        newsletterOptIn = isNewAccount || ServerSettings.marketingOptIn()

        guard !isNewAccount else { return }

        // The account's setting arrives with the first sync, which can finish after this screen is shown.
        syncObserver = NotificationCenter.default.publisher(for: ServerNotifications.syncCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showSyncedNewsletterOptIn()
            }
    }

    func setupPermissions() async {
        let coordinator = NotificationsCoordinator.shared
        await coordinator.requestAndSetupInitialPermissions()
    }

    func toggleNewsletterOptIn() {
        newsletterOptIn.toggle()
        didChangeNewsletterOptIn = true
    }

    /// Whether Save Preferences has a newsletter choice to store.
    var shouldSaveNewsletterOptIn: Bool {
        isNewAccount || didChangeNewsletterOptIn
    }

    func saveNewsletterOptIn() {
        guard shouldSaveNewsletterOptIn else { return }

        ServerSettings.setMarketingOptIn(newsletterOptIn)
        Analytics.track(.newsletterOptInChanged, properties: ["enabled": newsletterOptIn, "source": "notifications_permissions"])
    }

    func showSyncedNewsletterOptIn() {
        guard !isNewAccount, !didChangeNewsletterOptIn else { return }

        newsletterOptIn = ServerSettings.marketingOptIn()
    }

    enum NotificationOption: CaseIterable {
        case newsletter
        case notifications

        var title: String {
            switch self {
            case .newsletter:
                return L10n.notificationsOnboardingNewsletterTitle
            case .notifications:
                return L10n.notificationsOnboardingNotificationsTitle
            }
        }

        var subtitle: String {
            switch self {
            case .newsletter:
                return L10n.notificationsOnboardingNewsletterSubtitle
            case .notifications:
                return L10n.notificationsOnboardingNotificationsSubtitle
            }
        }

        func isSelected(_ viewModel: NotificationsPermissionsViewModel) -> Bool {
            switch self {
            case .newsletter:
                return viewModel.newsletterOptIn
            case .notifications:
                return viewModel.notificationsOptIn
            }
        }

        func toggle(_ viewModel: NotificationsPermissionsViewModel) {
            switch self {
            case .newsletter:
                viewModel.toggleNewsletterOptIn()
            case .notifications:
                viewModel.notificationsOptIn.toggle()
            }
        }
    }

    static func makeController(isNewAccount: Bool) -> UIViewController {
        let viewModel = NotificationsPermissionsViewModel(isNewAccount: isNewAccount)

        let view = NotificationsPermissionsView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view.setupDefaultEnvironment())

        return  controller
    }
}

struct NotificationsPermissionsView: View {

    @Environment(\.dismiss) private var dismissAction

    @EnvironmentObject var theme: Theme

    @StateObject var viewModel = NotificationsPermissionsViewModel()

    @ViewBuilder
    private func optionRow(for option: NotificationsPermissionsViewModel.NotificationOption) -> some View {
        Button {
            option.toggle(viewModel)
        } label: {
            HStack(spacing: 17) {
                Button {
                    option.toggle(viewModel)
                } label: {
                    EmptyView() // content is provided by the style
                }
                .buttonStyle(
                    SelectCircleButtonStyle(selected: .constant(option.isSelected(viewModel)))
                )
                .environmentObject(Theme.shared)
                .accessibilityHidden(true)
                VStack(alignment: .leading) {
                    Text(option.title)
                        .font(style: .subheadline, weight: .medium)
                        .foregroundStyle(theme.primaryText01)
                    Text(option.subtitle)
                        .font(.footnote)
                        .foregroundStyle(theme.primaryText02)
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(option.isSelected(viewModel) ? .isSelected : [])
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(maxHeight: 136)
                    ViewThatFits(in: .vertical) {
                        Image("notifications_permissions_banner")
                        Image("notifications_permissions_banner")
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(maxHeight: proxy.size.height * 0.42)
                    Spacer().frame(height: 24)
                    Text(L10n.notificationsPermissionsTitle)
                        .textStyle(PrimaryText())
                        .font(.largeTitle.bold())
                    Spacer().frame(height: 20)
                    Text(L10n.notificationsPermissionsBody)
                        .textStyle(SecondaryText())
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    VStack(alignment: .leading, spacing: 24) {
                        if viewModel.showNewsletterOptIn {
                            optionRow(for: .newsletter)
                        }
                        optionRow(for: .notifications)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 34)
                    .padding(.horizontal, 4)
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ZStack {
                Button(action: {
                    Analytics.track(.notificationsPermissionsAllowTapped)
                    if viewModel.showNewsletterOptIn {
                        viewModel.saveNewsletterOptIn()
                    }
                    Task {
                        if viewModel.notificationsOptIn {
                            await viewModel.setupPermissions()
                        }
                        dismissAction()
                    }
                }) {
                    Text(L10n.notificationsPermissionsSavePreferences)
                        .textStyle(RoundedButton())
                }
            }
            .padding(16)
            .background(
                LinearGradient(gradient: Gradient(stops: [
                    Gradient.Stop(color: theme.primaryUi01.opacity(0.0), location: 0.0),
                    Gradient.Stop(color: theme.primaryUi01, location: 0.1),
                ]), startPoint: .top, endPoint: .bottom)
            )
        }
        .background(theme.primaryUi01)
        .onAppear() {
            Analytics.track(.notificationsPermissionsShown)
        }
    }
}

struct NotificationsPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsPermissionsView()
            .environmentObject(Theme(previewTheme: .light))
    }
}
