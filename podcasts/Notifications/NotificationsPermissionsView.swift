import SwiftUI
import PocketCastsUtils
import PocketCastsServer

class NotificationsPermissionsViewModel: ObservableObject {
    @Published var newsletterOptIn: Bool = true
    @Published var notificationsOptIn: Bool = true

    func setupPermissions() async {
        let coordinator = NotificationsCoordinator.shared
        await coordinator.requestAndSetupInitialPermissions()
    }

    func saveNewsletterOptIn() {
        ServerSettings.setMarketingOptIn(newsletterOptIn)
    }

    func trackNewsletterOptIn() {
        Analytics.track(.newsletterOptInChanged, properties: ["enabled": newsletterOptIn, "source": "notifications_permissions"])
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
                viewModel.newsletterOptIn.toggle()
            case .notifications:
                viewModel.notificationsOptIn.toggle()
            }
        }
    }

    static func makeController() -> UIViewController {
        let viewModel = NotificationsPermissionsViewModel()

        let view = NotificationsPermissionsView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view.setupDefaultEnvironment())

        return  controller
    }
}

struct NotificationsPermissionsView: View {

    @Environment(\.dismiss) private var dismissAction

    @EnvironmentObject var theme: Theme

    @StateObject var viewModel: NotificationsPermissionsViewModel = NotificationsPermissionsViewModel()

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
                .environmentObject(Theme.sharedTheme)
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
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    if FeatureFlag.newOnboardingAccountCreation.enabled {
                        Spacer()
                            .frame(maxHeight: 136)
                    } else {
                        Button(action: {
                            Analytics.track(.notificationsPermissionsNotNowTapped)
                            dismissAction()
                        }) {
                            HStack {
                                Spacer()
                                Text(L10n.eoyNotNow)
                                    .foregroundStyle(theme.primaryInteractive01)
                                    .font(.body.weight(.medium))
                            }
                        }
                    }
                    Image("notifications_permissions_banner")
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
                    if FeatureFlag.newOnboardingAccountCreation.enabled {
                        VStack(alignment: .leading, spacing: 24) {
                            optionRow(for: .newsletter)
                            optionRow(for: .notifications)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 34)
                        .padding(.horizontal, 4)
                    }
                    Spacer()
                    Rectangle().fill(.clear).frame(height: 44)
                }
                .padding(.horizontal, 16)
            }
            ZStack {
                Button(action: {
                    Analytics.track(.notificationsPermissionsAllowTapped)
                    viewModel.saveNewsletterOptIn()
                    viewModel.trackNewsletterOptIn()
                    Task {
                        if viewModel.notificationsOptIn {
                            await viewModel.setupPermissions()
                        }
                        dismissAction()
                    }
                }) {
                    Text(FeatureFlag.newOnboardingAccountCreation.enabled ? L10n.notificationsPermissionsSavePreferences : L10n.notificationsPermissionsAction)
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
