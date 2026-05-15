import SwiftUI
import PhotosUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct ShareProfileView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: ShareProfileViewModel

    var dismissAction: () -> Void
    var onOpenPrivacySettings: (() -> Void)?

    enum Step {
        case addPhotoAndName
        case preview
        case edit
        case allPodcasts
        case allEpisodes
    }

    @State private var path: [Step] = []

    @State private var initialShareFollowedPodcasts: Bool = true
    @State private var initialShareRecentEpisodes: Bool = true
    @State private var initialSharePlaylists: Bool = true
    @State private var startOnPreview: Bool = false

    private var hasEditChanges: Bool {
        viewModel.shareFollowedPodcasts != initialShareFollowedPodcasts ||
        viewModel.shareRecentEpisodes != initialShareRecentEpisodes ||
        viewModel.sharePlaylists != initialSharePlaylists
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if startOnPreview {
                    previewProfileView()
                } else {
                    addPhotoAndNameView()
                }
            }
            .navigationDestination(for: Step.self) { step in
                switch step {
                case .addPhotoAndName:
                    addPhotoAndNameView()
                case .preview:
                    previewProfileView()
                case .edit:
                    editProfileView()
                case .allPodcasts:
                    allPodcastsView()
                case .allEpisodes:
                    allEpisodesView()
                }
            }
        }
        .onAppear {
            startOnPreview = viewModel.profilePhoto != nil && !viewModel.displayName.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    // MARK: - Step 1: Add Photo and Name

    @ViewBuilder
    private func addPhotoAndNameView() -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    ProfilePhotoMenu(viewModel: viewModel)
                    DisplayNameField(displayName: $viewModel.displayName)
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
            }

            Spacer()

            BottomGradientContainer {
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

            BottomGradientContainer {
                shareMyProfileButton()
            }
        }
        .background(theme.primaryUi01)
        .navigationTitle(L10n.shareProfilePreview)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if startOnPreview && path.isEmpty {
                    Button(action: dismissAction) {
                        Image("cancel")
                            .renderingMode(.template)
                    }
                    .navThemed()
                    .accessibilityLabel(L10n.accessibilityCloseDialog)
                } else {
                    Button {
                        path.removeLast()
                    } label: {
                        Image("nav-back")
                            .renderingMode(.template)
                    }
                    .navThemed()
                }
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
                sectionHeader(L10n.shareProfileFollowedPodcasts) {
                        path.append(.allPodcasts)
                    }
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

        VStack(alignment: .leading, spacing: 0) {
            PodcastImage(uuid: podcast.uuid)
                .frame(width: cardWidth, height: cardWidth)
                .cornerRadius(4)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                .padding(.bottom, 8)

            Text(podcast.title ?? "")
                .font(style: .subheadline, weight: .medium)
                .foregroundColor(theme.primaryText01)
                .lineLimit(1)
                .padding(.bottom, 2)

            if let author = podcast.author {
                Text(author)
                    .font(style: .footnote, weight: .regular)
                    .foregroundColor(theme.primaryText02)
                    .lineLimit(1)
            }
        }
        .frame(width: cardWidth)
    }

    @ViewBuilder
    private func previewEpisodesSection() -> some View {
        let episodes = Array(viewModel.recentEpisodes.prefix(8))
        if !episodes.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader(L10n.shareProfileRecentEpisodes) {
                    path.append(.allEpisodes)
                }

                ForEach(Array(episodes.enumerated()), id: \.element.uuid) { index, episode in
                    HStack(spacing: 12) {
                        PodcastImage(uuid: episode.podcastUuid)
                            .frame(width: 56, height: 56)
                            .cornerRadius(4)
                            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)

                        VStack(alignment: .leading, spacing: 2) {
                            if let date = episode.publishedDate {
                                Text(DateFormatHelper.sharedHelper.tinyLocalizedFormat(date).localizedUppercase)
                                    .font(style: .caption2, weight: .bold)
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
    private func sectionHeader(_ title: String, showAllAction: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title)
                .font(style: .headline, weight: .bold)
                .foregroundColor(theme.primaryText01)
            Spacer()
            if let showAllAction {
                Button(action: showAllAction) {
                    Text(L10n.discoverShowAll)
                        .font(style: .caption, weight: .bold)
                        .foregroundColor(theme.primaryInteractive01)
                }
            } else {
                Text(L10n.discoverShowAll)
                    .font(style: .caption, weight: .bold)
                    .foregroundColor(theme.primaryInteractive01)
            }
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
            HStack(spacing: 8) {
                    Image("podcast-share")
                        .renderingMode(.template)
                    Text(L10n.shareProfileShareMyProfile)
                }
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

    // MARK: - All Followed Podcasts

    @ViewBuilder
    private func allPodcastsView() -> some View {
        let podcasts = viewModel.followedPodcasts
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(podcasts.enumerated()), id: \.element.uuid) { index, podcast in
                        HStack(spacing: 12) {
                            PodcastImage(uuid: podcast.uuid)
                                .frame(width: 52, height: 52)
                                .cornerRadius(4)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(podcast.title ?? "")
                                    .font(style: .subheadline, weight: .medium)
                                    .foregroundColor(theme.primaryText01)
                                    .lineLimit(1)

                                if let author = podcast.author {
                                    Text(author)
                                        .font(style: .footnote, weight: .regular)
                                        .foregroundColor(theme.primaryText02)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)

                        if index < podcasts.count - 1 {
                            ThemedDivider()
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }

            BottomGradientContainer {
                shareMyProfileButton()
            }
        }
        .background(theme.primaryUi01)
        .navigationTitle(L10n.shareProfileFollowedPodcasts)
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

    // MARK: - All Recent Episodes

    @ViewBuilder
    private func allEpisodesView() -> some View {
        let episodes = viewModel.recentEpisodes
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(episodes.enumerated()), id: \.element.uuid) { index, episode in
                        HStack(spacing: 12) {
                            PodcastImage(uuid: episode.podcastUuid)
                                .frame(width: 56, height: 56)
                                .cornerRadius(4)

                            VStack(alignment: .leading, spacing: 2) {
                                if let date = episode.publishedDate {
                                    Text(DateFormatHelper.sharedHelper.tinyLocalizedFormat(date).localizedUppercase)
                                        .font(style: .caption2, weight: .bold)
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

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)

                        if index < episodes.count - 1 {
                            ThemedDivider()
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }

            BottomGradientContainer {
                shareMyProfileButton()
            }
        }
        .background(theme.primaryUi01)
        .navigationTitle(L10n.shareProfileRecentEpisodes)
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

            BottomGradientContainer {
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
                    viewModel.shareFollowedPodcasts = initialShareFollowedPodcasts
                    viewModel.shareRecentEpisodes = initialShareRecentEpisodes
                    viewModel.sharePlaylists = initialSharePlaylists
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

        if let onOpenPrivacySettings {
            Button(action: onOpenPrivacySettings) {
                Text(privacyLinkAttributedString(fullText: fullText, link: privacyLabel))
                    .font(style: .caption)
                    .foregroundColor(theme.primaryText02)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(.plain)
        } else {
            Text(privacyLinkAttributedString(fullText: fullText, link: privacyLabel))
                .font(style: .caption)
                .foregroundColor(theme.primaryText02)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
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

// MARK: - Edit Photo and Name (standalone)

struct EditPhotoAndNameView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: ShareProfileViewModel

    var dismissAction: () -> Void

    @State private var initialDisplayName: String = ""
    @State private var initialPhoto: UIImage?

    private var hasChanges: Bool {
        viewModel.displayName != initialDisplayName || viewModel.profilePhoto !== initialPhoto
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        ProfilePhotoMenu(viewModel: viewModel)
                        DisplayNameField(displayName: $viewModel.displayName)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                }

                Spacer()

                BottomGradientContainer {
                    Button {
                        dismissAction()
                    } label: {
                        Text(L10n.shareProfileSave)
                            .font(style: .body, weight: .semibold)
                            .foregroundColor(theme.primaryInteractive02)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(theme.primaryInteractive01.opacity(hasChanges ? 1 : 0.4))
                            .cornerRadius(ViewConstants.buttonCornerRadius)
                    }
                    .disabled(!hasChanges)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .background(theme.primaryUi01)
            .navigationTitle(L10n.shareProfileEditPhotoAndName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.displayName = initialDisplayName
                        viewModel.profilePhoto = initialPhoto
                        dismissAction()
                    } label: {
                        Image("cancel")
                            .renderingMode(.template)
                    }
                    .navThemed()
                    .accessibilityLabel(L10n.accessibilityCloseDialog)
                }
            }
        }
        .onAppear {
            initialDisplayName = viewModel.displayName
            initialPhoto = viewModel.profilePhoto
        }
    }
}

// MARK: - Shared Components

private struct ProfilePhotoMenu: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: ShareProfileViewModel

    var body: some View {
        VStack(spacing: 12) {
            Menu {
                Button {
                    viewModel.showingPhotoPicker = true
                } label: {
                    Label(L10n.shareProfileChoosePhoto, systemImage: "photo.on.rectangle")
                }

                Button {
                    viewModel.showingCamera = true
                } label: {
                    Label(L10n.shareProfileTakePhoto, systemImage: "camera")
                }

                if viewModel.profilePhoto != nil {
                    Divider()

                    Button(role: .destructive) {
                        viewModel.removePhoto()
                    } label: {
                        Label(L10n.shareProfileRemovePhoto, systemImage: "trash")
                    }
                }
            } label: {
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
                        .overlay(Circle().stroke(theme.primaryUi01, lineWidth: 3))
                }
            }
        }
        .photosPicker(isPresented: $viewModel.showingPhotoPicker, selection: $viewModel.selectedPhotoItem, matching: .images)
        .fullScreenCover(isPresented: $viewModel.showingCamera) {
            CameraPicker { image in
                viewModel.profilePhoto = image
            }
            .ignoresSafeArea()
        }
    }
}

private struct DisplayNameField: View {
    @EnvironmentObject var theme: Theme
    @Binding var displayName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.shareProfileDisplayName)
                .font(style: .subheadline, weight: .semibold)
                .foregroundColor(theme.primaryText01)

            TextField(L10n.shareProfileAddYourName, text: $displayName)
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
}

private struct BottomGradientContainer<Content: View>: View {
    @EnvironmentObject var theme: Theme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
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

            content
                .background(theme.primaryUi01)
        }
    }
}

// MARK: - Camera Picker

struct CameraPicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview

struct ShareProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ShareProfileView(viewModel: ShareProfileViewModel(), dismissAction: {})
            .setupDefaultEnvironment()
    }
}
