import SwiftUI

/// Common view to display the profile email / display name labels if they're available
struct ProfileInfoLabels: View {
    @EnvironmentObject var theme: Theme

    let profile: UserInfo.Profile
    var alignment: HorizontalAlignment = .center
    var spacing: Double = 0

    var body: some View {
        labels()
        // Force SwiftUI to reload the view when any of the data changes since sometimes it won't
        .id("\(profile.isLoggedIn)_\(profile.displayName ?? "none")_\(profile.email ?? "none")")
    }

    @ViewBuilder
    private func labels() -> some View {
        if let email = profile.email {
            VStack(alignment: alignment, spacing: spacing) {
                // Verify we have at least the email to display
                VStack(alignment: alignment, spacing: 4) {
                    profile.displayName.map {
                        Text($0)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(style: .title2, weight: .bold)
                            .foregroundColor(theme.primaryText01)
                    }

                    // Verbatim prevents the Text from autolinking the email
                    Text(verbatim: email)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(style: .footnote, weight: .semibold)
                        .foregroundColor(theme.primaryText02)
                }
            }
        } else {
            EmptyView()
        }
    }
}

// MARK: - Previews
struct ProfileInfoLabels_Previews: PreviewProvider {
    static var previews: some View {
        PreviewContent()
            .setupDefaultEnvironment()
    }

    private struct PreviewContent: View {
        @EnvironmentObject var theme: Theme

        var body: some View {
            VStack(spacing: 20) {
                Divider()
                Group {
                    Text("Email + Display Name")
                        .font(.headline)

                    ProfileInfoLabels(profile: .init(isLoggedIn: true,
                                                     email: "hello@world.com",
                                                     displayName: "Hello World"))
                    Divider()
                }


                Group {
                    Text("Just Email")
                        .font(.headline)

                    ProfileInfoLabels(profile: .init(isLoggedIn: true,
                                                     email: "hello@world.com",
                                                     displayName: nil))

                    Divider()
                }

                Group {
                    Text("A Really Long Email")
                        .font(.headline)

                    ProfileInfoLabels(profile: .init(isLoggedIn: true,
                                                     email: "heeeeeeeeeeeeeeeeeeeeeeellllllllllooooooooooooo@wwwwwwoooooorrrrrrrrrrrllllllllllllllllllld.com",
                                                     displayName: nil))
                    Divider()
                }

                Group {
                    Text("A Really Long Email + really long display name")
                        .font(.headline)

                    ProfileInfoLabels(profile: .init(isLoggedIn: true,
                                                     email: "supercalifragilisticexpialidocious.antidisestablishmentarianism.hippopotomonstrosesquippedaliophobia.pneumonoultramicroscopicsilicovolcanoconiosis.chronopotentiometry@emailprovider.com",
                                                     displayName: "Hellllllllllllllllllllllloooooooooooo Worrrrrrrrrrrllllllddd"))
                    Divider()
                }

            }
            .padding()
            .background(theme.primaryUi01)
        }
    }
}
