import SwiftUI
import PhotosUI
import PocketCastsDataModel
import PocketCastsServer

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

            continueButton()
        }
        .background(theme.primaryUi01)
        .navigationTitle(L10n.shareProfileAddPhotoAndName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.primaryText01)
                }
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
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        ProfileImage(email: viewModel.email)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    }

                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(ThemeColor.primaryInteractive01(for: theme.activeTheme)))
                        .background(Circle().fill(theme.primaryUi01).frame(width: 22, height: 22))
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
                .font(.body)
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

    @ViewBuilder
    private func continueButton() -> some View {
        Button {
            path.append(.preview)
        } label: {
            Text(L10n.continue)
                .font(style: .body, weight: .semibold)
                .foregroundColor(Color(ThemeColor.primaryInteractive02(for: theme.activeTheme)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(ThemeColor.primaryInteractive01(for: theme.activeTheme)))
                .cornerRadius(ViewConstants.buttonCornerRadius)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
    }

    // MARK: - Step 2: Preview Profile

    @ViewBuilder
    private func previewProfileView() -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    previewHeader()

                    if viewModel.shareFollowedPodcasts {
                        previewPodcastsSection()
                    }

                    if viewModel.shareRecentEpisodes {
                        previewEpisodesSection()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            shareMyProfileButton()
        }
        .background(theme.primaryUi01)
        .navigationTitle(L10n.shareProfilePreview)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    path.append(.edit)
                } label: {
                    Image("share-profile-settings")
                        .renderingMode(.template)
                        .foregroundColor(Color(ThemeColor.primaryInteractive01(for: theme.activeTheme)))
                }
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
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                ProfileImage(email: viewModel.email)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            }

            if !viewModel.displayName.isEmpty {
                Text(viewModel.displayName)
                    .font(.title3.bold())
                    .foregroundColor(theme.primaryText01)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func previewPodcastsSection() -> some View {
        let podcasts = Array(viewModel.followedPodcasts.prefix(3))
        if !podcasts.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(L10n.shareProfileFollowedPodcasts)
                        .font(style: .subheadline, weight: .bold)
                        .foregroundColor(theme.primaryText01)
                    Spacer()
                    Text(L10n.discoverShowAll)
                        .font(style: .caption, weight: .bold)
                        .foregroundColor(Color(ThemeColor.primaryInteractive01(for: theme.activeTheme)))
                }
                .padding(.bottom, 16)

                ForEach(Array(podcasts.enumerated()), id: \.element.uuid) { index, podcast in
                    HStack(spacing: 12) {
                        let url = ImageManager.sharedManager.podcastUrl(imageSize: .grid, uuid: podcast.uuid)
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 56, height: 56)
                        .cornerRadius(8)

                        Text(podcast.title ?? "")
                            .font(style: .body, weight: .medium)
                            .foregroundColor(theme.primaryText01)
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.primaryText02)
                    }
                    .padding(.vertical, 8)

                    if index < podcasts.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func previewEpisodesSection() -> some View {
        let episodes = Array(viewModel.recentEpisodes.prefix(3))
        if !episodes.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(L10n.shareProfileRecentEpisodes)
                        .font(style: .subheadline, weight: .bold)
                        .foregroundColor(theme.primaryText01)
                    Spacer()
                    Text(L10n.discoverShowAll)
                        .font(style: .caption, weight: .bold)
                        .foregroundColor(Color(ThemeColor.primaryInteractive01(for: theme.activeTheme)))
                }
                .padding(.bottom, 16)

                ForEach(Array(episodes.enumerated()), id: \.element.uuid) { index, episode in
                    HStack(spacing: 12) {
                        let url = ImageManager.sharedManager.podcastUrl(imageSize: .grid, uuid: episode.podcastUuid)
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 56, height: 56)
                        .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 2) {
                            if let date = episode.publishedDate {
                                Text(date.formatted(.dateTime.month(.wide).day()))
                                    .font(style: .caption2, weight: .semibold)
                                    .foregroundColor(theme.primaryText02)
                                    .textCase(.uppercase)
                            }

                            Text(episode.title ?? "")
                                .font(style: .subheadline, weight: .medium)
                                .foregroundColor(theme.primaryText01)
                                .lineLimit(1)

                            let minutes = Int(episode.duration / 60)
                            if minutes > 0 {
                                Text("\(minutes) mins")
                                    .font(style: .caption2)
                                    .foregroundColor(theme.primaryText02)
                            }
                        }

                        Spacer()

                        Image(systemName: "play.circle")
                            .font(.system(size: 28))
                            .foregroundColor(Color(ThemeColor.primaryInteractive01(for: theme.activeTheme)))
                    }
                    .padding(.vertical, 8)

                    if index < episodes.count - 1 {
                        Divider()
                    }
                }
            }
        }
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
                .foregroundColor(Color(ThemeColor.primaryInteractive02(for: theme.activeTheme)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(ThemeColor.primaryInteractive01(for: theme.activeTheme)))
                .cornerRadius(ViewConstants.buttonCornerRadius)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
    }

    // MARK: - Step 3: Edit Profile

    @ViewBuilder
    private func editProfileView() -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.shareProfileWhatToShare)
                    .font(style: .title3, weight: .bold)
                    .foregroundColor(theme.primaryText01)
                    .padding(.top, 24)

                VStack(spacing: 0) {
                    editToggleRow(
                        title: L10n.shareProfileFollowedPodcasts,
                        isOn: $viewModel.shareFollowedPodcasts
                    )

                    Divider()

                    editToggleRow(
                        title: L10n.shareProfileRecentEpisodes,
                        isOn: $viewModel.shareRecentEpisodes
                    )

                    Divider()

                    editToggleRow(
                        title: L10n.shareProfilePlaylists,
                        isOn: $viewModel.sharePlaylists
                    )
                }

                Text(L10n.shareProfilePrivacyDescription)
                    .font(style: .caption)
                    .foregroundColor(theme.primaryText02)
            }
            .padding(.horizontal, 20)

            Spacer()

            saveButton()
        }
        .background(theme.primaryUi01)
        .navigationTitle(L10n.shareProfileEdit)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func editToggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(style: .body)
                .foregroundColor(theme.primaryText01)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color(ThemeColor.primaryInteractive01(for: theme.activeTheme)))
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func saveButton() -> some View {
        Button {
            path.removeLast()
        } label: {
            Text(L10n.shareProfileSave)
                .font(style: .body, weight: .semibold)
                .foregroundColor(Color(ThemeColor.primaryInteractive02(for: theme.activeTheme)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(ThemeColor.primaryInteractive01(for: theme.activeTheme)))
                .cornerRadius(ViewConstants.buttonCornerRadius)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
    }
}

// MARK: - Preview

struct ShareProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ShareProfileView(viewModel: ShareProfileViewModel(), dismissAction: {})
            .setupDefaultEnvironment()
    }
}
