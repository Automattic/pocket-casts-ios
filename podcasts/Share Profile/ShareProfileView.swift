import SwiftUI
import PhotosUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct ShareProfileView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: ShareProfileViewModel

    var dismissAction: () -> Void

    enum Step {
        case addPhotoAndName
        case preview
        case edit
    }

    @State private var path: [Step] = []

    @State private var initialShareFollowedPodcasts: Bool = true
    @State private var initialShareRecentEpisodes: Bool = true
    @State private var initialSharePlaylists: Bool = true

    private var hasEditChanges: Bool {
        viewModel.shareFollowedPodcasts != initialShareFollowedPodcasts ||
        viewModel.shareRecentEpisodes != initialShareRecentEpisodes ||
        viewModel.sharePlaylists != initialSharePlaylists
    }

    var body: some View {
        NavigationStack(path: $path) {
            addPhotoAndNameView()
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .addPhotoAndName:
                        addPhotoAndNameView()
                    case .preview:
                        previewProfileView()
                    case .edit:
                        editProfileView()
                    }
                }
        }
    }

    // MARK: - Step 1: Add Photo and Name

    @ViewBuilder
    private func addPhotoAndNameView() -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    photoSection()
                    nameSection()
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
            }

            Spacer()

            bottomButton {
                continueButton()
            }
        }
        .background(theme.primaryUi01)
        .navigationTitle(L10n.shareProfileAddPhotoAndName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: dismissAction) {
                    Image("cancel")
                        .renderingMode(.template)
                }
                .navThemed()
                .accessibilityLabel(L10n.accessibilityCloseDialog)
            }
        }
    }

    @ViewBuilder
    private func photoSection() -> some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let photo = viewModel.profilePhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 134, height: 134)
                            .clipShape(Circle())
                    } else {
                        ProfileImage(email: viewModel.email)
                            .frame(width: 134, height: 134)
                            .clipShape(Circle())
                    }

                    Image("folder-edit")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(theme.primaryInteractive02)
                        .frame(width: 24, height: 24)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(theme.primaryInteractive01))
                        .clipShape(Circle())
                }
            }
        }
    }

    @ViewBuilder
    private func nameSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.shareProfileDisplayName)
                .font(style: .subheadline, weight: .semibold)
                .foregroundColor(theme.primaryText01)

            TextField(L10n.shareProfileAddYourName, text: $viewModel.displayName)
                .font(style: .body)
                .foregroundColor(theme.primaryText01)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.primaryUi05, lineWidth: 1)
                )

            Text(L10n.shareProfileNameDescription)
                .font(style: .caption, weight: .regular)
                .foregroundColor(theme.primaryText02)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
        }
    }

    private var canContinue: Bool {
        viewModel.profilePhoto != nil && !viewModel.displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @ViewBuilder
    private func continueButton() -> some View {
        Button {
            path.append(.preview)
        } label: {
            Text(L10n.continue)
                .font(style: .body, weight: .semibold)
                .foregroundColor(theme.primaryInteractive02)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(theme.primaryInteractive01.opacity(canContinue ? 1 : 0.4))
                .cornerRadius(ViewConstants.buttonCornerRadius)
        }
        .disabled(!canContinue)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Step 2: Preview Profile

    @ViewBuilder
    private func previewProfileView() -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    previewHeader()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    if viewModel.shareFollowedPodcasts {
                        previewPodcastsSection()
                    }

                    if viewModel.shareRecentEpisodes {
                        if viewModel.shareFollowedPodcasts {
                            ThemedDivider()
                                .padding(.horizontal, 20)
                                .padding(.vertical, 24)
                        }

                        previewEpisodesSection()
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 32)
                .padding(.bottom, 80)
            }

            bottomButton {
                shareMyProfileButton()
            }
        }
        .background(theme.primaryUi01)
        .navigationTitle(L10n.shareProfilePreview)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    path.removeLast()
                } label: {
                    Image("nav-back")
                        .renderingMode(.template)
                }
                .navThemed()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    path.append(.edit)
                } label: {
                    Image("profile-settings")
                        .renderingMode(.template)
                }
                .navThemed()
            }
        }
    }

    @ViewBuilder
    private func previewHeader() -> some View {
        VStack(spacing: 8) {
            if let photo = viewModel.profilePhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 134, height: 134)
                    .clipShape(Circle())
            } else {
                ProfileImage(email: viewModel.email)
                    .frame(width: 134, height: 134)
                    .clipShape(Circle())
            }

            if !viewModel.displayName.isEmpty {
                Text(viewModel.displayName)
                    .font(style: .title3, weight: .bold)
                    .foregroundColor(theme.primaryText01)
            }
        }
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func previewPodcastsSection() -> some View {
        let podcasts = Array(viewModel.followedPodcasts.prefix(8))
        if !podcasts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(L10n.shareProfileFollowedPodcasts)
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(podcasts, id: \.uuid) { podcast in
                            podcastCard(podcast)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    @ViewBuilder
    private func podcastCard(_ podcast: Podcast) -> some View {
        let cardWidth: CGFloat = 150

        VStack(alignment: .leading, spacing: 8) {
            PodcastImage(uuid: podcast.uuid)
                .frame(width: cardWidth, height: cardWidth)
                .cornerRadius(4)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)

            Text(podcast.title ?? "")
                .font(style: .subheadline, weight: .medium)
                .foregroundColor(theme.primaryText01)
                .lineLimit(1)

            if let author = podcast.author {
                Text(author)
                    .font(style: .caption, weight: .regular)
                    .foregroundColor(theme.primaryText02)
                    .lineLimit(1)
            }
        }
        .frame(width: cardWidth)
    }

    @ViewBuilder
    private func previewEpisodesSection() -> some View {
        let episodes = Array(viewModel.recentEpisodes.prefix(3))
        if !episodes.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader(L10n.shareProfileRecentEpisodes)

                ForEach(Array(episodes.enumerated()), id: \.element.uuid) { index, episode in
                    HStack(spacing: 12) {
                        PodcastImage(uuid: episode.podcastUuid)
                            .frame(width: 56, height: 56)
                            .cornerRadius(4)
                            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)

                        VStack(alignment: .leading, spacing: 2) {
                            if let date = episode.publishedDate {
                                Text(DateFormatHelper.sharedHelper.tinyLocalizedFormat(date).localizedUppercase)
                                    .font(style: .footnote, weight: .bold)
                                    .foregroundColor(theme.primaryText02)
                            }

                            Text(episode.title ?? "")
                                .font(style: .subheadline, weight: .medium)
                                .foregroundColor(theme.primaryText01)
                                .lineLimit(2)

                            Text(TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(episode.duration)))
                                .font(style: .caption, weight: .semibold)
                                .foregroundColor(theme.primaryText02)
                        }

                    }
                    .padding(.vertical, 12)

                    if index < episodes.count - 1 {
                        ThemedDivider()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(style: .title3, weight: .bold)
                .foregroundColor(theme.primaryText01)
            Spacer()
            Text(L10n.discoverShowAll)
                .font(style: .caption, weight: .bold)
                .foregroundColor(theme.primaryInteractive01)
        }
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func shareMyProfileButton() -> some View {
        Button {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController {
                var presenter = rootVC
                while let presented = presenter.presentedViewController {
                    presenter = presented
                }
                viewModel.shareProfile(from: presenter)
            }
        } label: {
            Label(L10n.shareProfileShareMyProfile, systemImage: "square.and.arrow.up")
                .font(style: .body, weight: .semibold)
                .foregroundColor(theme.primaryInteractive02)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(theme.primaryInteractive01)
                .cornerRadius(ViewConstants.buttonCornerRadius)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Step 3: Edit Profile

    @ViewBuilder
    private func editProfileView() -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    editProfileHeader()

                    Text(L10n.shareProfileWhatToShare)
                        .font(style: .title3, weight: .bold)
                        .foregroundColor(theme.primaryText01)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 12) {
                        editToggleRow(
                            title: L10n.shareProfileFollowedPodcasts,
                            icon: "podcasts_tab",
                            isOn: $viewModel.shareFollowedPodcasts
                        )

                        editToggleRow(
                            title: L10n.shareProfileRecentEpisodes,
                            icon: "profile-history",
                            isOn: $viewModel.shareRecentEpisodes
                        )

                        editToggleRow(
                            title: L10n.shareProfilePlaylists,
                            icon: "filter_list",
                            isOn: $viewModel.sharePlaylists
                        )
                    }

                    privacyFooter()
                        .padding(.top, -8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
            }

            Spacer()

            bottomButton {
                saveButton()
            }
        }
        .background(theme.primaryUi01)
        .onAppear {
            initialShareFollowedPodcasts = viewModel.shareFollowedPodcasts
            initialShareRecentEpisodes = viewModel.shareRecentEpisodes
            initialSharePlaylists = viewModel.sharePlaylists
        }
        .navigationTitle(L10n.shareProfileEdit)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    path.removeLast()
                } label: {
                    Image("nav-back")
                        .renderingMode(.template)
                }
                .navThemed()
            }
        }
    }

    @ViewBuilder
    private func editProfileHeader() -> some View {
        VStack(spacing: 8) {
            if let photo = viewModel.profilePhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 134, height: 134)
                    .clipShape(Circle())
            } else {
                ProfileImage(email: viewModel.email)
                    .frame(width: 134, height: 134)
                    .clipShape(Circle())
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func editToggleRow(title: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(theme.primaryText01)
                .frame(width: 24, height: 24)

            Text(title)
                .font(style: .body, weight: .semibold)
                .foregroundColor(theme.primaryText01)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(theme.primaryInteractive01)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(theme.primaryUi04)
        .cornerRadius(12)
    }

    @ViewBuilder
    private func privacyFooter() -> some View {
        let privacyLabel = L10n.shareProfilePrivacy
        let fullText = L10n.shareProfilePrivacyDescription(privacyLabel)

        Text(privacyLinkAttributedString(fullText: fullText, link: privacyLabel))
            .font(style: .caption)
            .foregroundColor(theme.primaryText02)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private func bottomButton<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                stops: [
                    .init(color: theme.primaryUi01.opacity(0), location: 0),
                    .init(color: theme.primaryUi01.opacity(0.5), location: 0.4),
                    .init(color: theme.primaryUi01, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 16)

            content()
                .background(theme.primaryUi01)
        }
    }

    private func privacyLinkAttributedString(fullText: String, link: String) -> AttributedString {
        var attributed = AttributedString(fullText)
        if let range = attributed.range(of: link) {
            attributed[range].foregroundColor = theme.primaryInteractive01
        }
        return attributed
    }

    @ViewBuilder
    private func saveButton() -> some View {
        Button {
            path.removeLast()
        } label: {
            Text(L10n.shareProfileSave)
                .font(style: .body, weight: .semibold)
                .foregroundColor(theme.primaryInteractive02)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(theme.primaryInteractive01.opacity(hasEditChanges ? 1 : 0.4))
                .cornerRadius(ViewConstants.buttonCornerRadius)
        }
        .disabled(!hasEditChanges)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Preview

struct ShareProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ShareProfileView(viewModel: ShareProfileViewModel(), dismissAction: {})
            .setupDefaultEnvironment()
    }
}
