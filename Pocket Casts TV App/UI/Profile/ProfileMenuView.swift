import SwiftUI

struct ProfileMenuView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss

    @State private var isShowingLogoutConfirmation = false

    /// Called with the chosen destination when the signed-out user taps
    /// "Log in" or "Create account". The presenter is responsible for
    /// dismissing this menu and showing the destination.
    let onAuthSelected: (AuthDestination) -> Void

    /// Called with the chosen destination when a signed-in user taps one of
    /// the content actions (e.g. "Starred Episodes"). The presenter is
    /// responsible for dismissing this menu and showing the destination.
    let onProfileSelected: (ProfileDestination) -> Void

    enum AuthDestination: Hashable, Identifiable {
        case signIn
        case createAccount
        var id: Self { self }
    }

    enum ProfileDestination: Hashable, Identifiable {
        case starred
        case history
        var id: Self { self }
    }

    var body: some View {
        Group {
            if coordinator.userState.isLoggedIn {
                signedInMenu
            } else {
                signedOutMenu
            }
        }
        .padding(80)
        .frame(width: 862, alignment: .center)
        .fixedSize(horizontal: true, vertical: false)
        .confirmationDialog(
            L10n.tvProfileMenuLogOutConfirmationTitle,
            isPresented: $isShowingLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.tvProfileMenuLogOut, role: .destructive) {
                coordinator.logout()
                dismiss()
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.tvProfileMenuLogOutConfirmationMessage)
        }
    }

    // MARK: - Signed-in

    private var signedInMenu: some View {
        VStack(spacing: 24) {
            if let email = coordinator.userState.usernameEmail {
                ProfileImage(email: email)
                    .frame(width: 160, height: 160)
                    .clipShape(Circle())
                Text(email)
                    .font(.title3)
                    .foregroundStyle(Color.pcTextPrimary)
                    .padding(.bottom, 24)
            }

            // Group 1
            Button {
                // Settings destination not yet implemented for TV
            } label: {
                Label(L10n.settings, systemImage: "gearshape")
                    .frame(minWidth: 400)
            }

            Divider()
                .frame(maxWidth: 400)

            // Group 2
            Button {
                onProfileSelected(.starred)
            } label: {
                Text(L10n.tvProfileMenuStarredEpisodes)
                    .frame(minWidth: 400)
            }
            Button {
                // Files destination not yet implemented for TV
            } label: {
                Text(L10n.files)
                    .frame(minWidth: 400)
            }
            Button {
                onProfileSelected(.history)
            } label: {
                Text(L10n.listeningHistory)
                    .frame(minWidth: 400)
            }

            Divider()
                .frame(maxWidth: 400)

            // Group 3
            Button {
                isShowingLogoutConfirmation = true
            } label: {
                Label(L10n.tvProfileMenuLogOut, systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(.red)
                    .frame(minWidth: 400)
            }
        }
    }

    // MARK: - Signed-out

    private var signedOutMenu: some View {
        VStack(spacing: 24) {
            Button {
                onAuthSelected(.signIn)
            } label: {
                Label(L10n.tvProfileMenuLogIn, systemImage: "person.crop.circle")
                    .frame(minWidth: 400)
            }
            Button {
                onAuthSelected(.createAccount)
            } label: {
                Label(L10n.tvProfileMenuCreateAccount, systemImage: "person.crop.circle.badge.plus")
                    .frame(minWidth: 400)
            }
        }
    }
}

#Preview {
    ProfileMenuView(onAuthSelected: { _ in }, onProfileSelected: { _ in })
        .environment(AppCoordinator())
}
