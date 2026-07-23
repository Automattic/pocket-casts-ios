import SwiftUI
import AVKit
import PocketCastsDataModel

struct NowPlayingView: View {
    @State private var model = NowPlayingViewModel()
    @State private var isShowingDescription = false
    @State private var isShowingMarkAsPlayedConfirmation = false
    @State private var isShowingArchiveConfirmation = false
    @State private var isShowingPodcast = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NowPlayingPlayerRepresentable(
            model: model,
            isShowingDescription: $isShowingDescription,
            isShowingMarkAsPlayedConfirmation: $isShowingMarkAsPlayedConfirmation,
            isShowingArchiveConfirmation: $isShowingArchiveConfirmation,
            isShowingPodcast: $isShowingPodcast
        )
        .onAppear {
            model.load()
            Analytics.track(.playerShown)
        }
        .onDisappear {
            Analytics.track(.playerDismissed)
        }
        .requireAccountSupport()
        .sheet(isPresented: $isShowingDescription) {
            if let episode = model.episode {
                EpisodeShowNotesView(episode: episode, podcast: model.podcast)
            }
        }
        // Mark Played and Archive both end playback (via
        // `EpisodeManager.markAsPlayed` / `archiveEpisode` →
        // `PlaybackManager.removeIfPlayingOrQueued`), so mirror the iOS
        // player and confirm before doing it. The reverse actions
        // (Mark Unplayed / Unarchive) skip confirmation since they
        // don't interrupt anything.
        .alert(L10n.playerMarkAsPlayedConfirmation, isPresented: $isShowingMarkAsPlayedConfirmation) {
            Button(L10n.markPlayedShort, role: .destructive) {
                AnalyticsEpisodeHelper.shared.currentSource = .player
                model.markAsPlayed()
                ToastManager.shared.show(L10n.markPlayedShort)
                dismiss()
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.playerMarkAsPlayedConfirmationMessage)
        }
        .alert(L10n.playerArchivedConfirmation, isPresented: $isShowingArchiveConfirmation) {
            Button(L10n.archive, role: .destructive) {
                AnalyticsEpisodeHelper.shared.currentSource = .player
                model.archive()
                ToastManager.shared.show(L10n.podcastArchived)
                dismiss()
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.playerArchivedConfirmationMessage)
        }
        .fullScreenCover(isPresented: $isShowingPodcast) {
            if let uuid = model.podcastUuid {
                PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: uuid))
                    .background(Color.pcBackgroundSurface)
            }
        }
    }
}

private struct NowPlayingPlayerRepresentable: UIViewControllerRepresentable {
    @Bindable var model: NowPlayingViewModel
    @Binding var isShowingDescription: Bool
    @Binding var isShowingMarkAsPlayedConfirmation: Bool
    @Binding var isShowingArchiveConfirmation: Bool
    @Binding var isShowingPodcast: Bool
    // Read here (rather than in the parent `NowPlayingView`) so the gated
    // implementation installed by `.requireAccountSupport()` — applied to
    // this representable above — is the one we see. Reading it upstream
    // would resolve to the default no-op that runs actions immediately.
    @Environment(\.requireAccount) private var requireAccount
    @State private var isTransportBarVisible = true

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.allowedSubtitleOptionLanguages = []
        controller.delegate = context.coordinator
        controller.appliesPreferredDisplayCriteriaAutomatically = false
        addOverlay(to: controller)
        return controller
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isTransportBarVisible: $isTransportBarVisible)
    }

    final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        @Binding var isTransportBarVisible: Bool

        init(isTransportBarVisible: Binding<Bool>) {
            self._isTransportBarVisible = isTransportBarVisible
        }

        func playerViewController(_ playerViewController: AVPlayerViewController, willTransitionToVisibilityOfTransportBar visible: Bool, with coordinator: any AVPlayerViewControllerAnimationCoordinator) {
            DispatchQueue.main.async { [weak self] in
                self?.isTransportBarVisible = visible
            }
        }
    }

    private func addOverlay(to controller: AVPlayerViewController) {
        guard let contentOverlayView = controller.contentOverlayView else {
            return
        }

        let overlayHostingController = UIHostingController(rootView: MediaOverlayView(model: model, isTransportBarVisible: $model.isLoading))

        guard let overlayView = overlayHostingController.view else {
            return
        }
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        controller.addChild(overlayHostingController)
        contentOverlayView.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: contentOverlayView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentOverlayView.bottomAnchor),
            overlayView.leftAnchor.constraint(equalTo: contentOverlayView.leftAnchor),
            overlayView.rightAnchor.constraint(equalTo: contentOverlayView.rightAnchor)
        ])

        overlayHostingController.didMove(toParent: controller)
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player != model.player {
            uiViewController.player = model.player
        }
        uiViewController.player?.currentItem?.externalMetadata = createMetadataItems()
        uiViewController.transportBarCustomMenuItems = [
            makePlaybackSpeedMenu(),
            makePlaybackEffectsMenu(),
            makeEpisodeActionsMenu()
        ].compactMap({$0})
        ensureEpisodeDescriptionInfoAction(on: uiViewController)
        // Suppress AVKit's system loading spinner while the player is still
        // preparing. Hiding playback controls also hides the spinner that
        // lives in the same transport overlay; our branded loading UI in
        // `MediaOverlayView` takes over during this window.
        let shouldShowControls = !model.isLoading
        if uiViewController.showsPlaybackControls != shouldShowControls {
            uiViewController.showsPlaybackControls = shouldShowControls
        }
    }

    private static let episodeDescriptionActionIdentifier = UIAction.Identifier("com.pocketcasts.tv.episodeDescription")

    /// Appends an "Episode details" action to the player's default Info tab
    /// alongside the system-provided "Play from Beginning" entry. Identifier-
    /// keyed so repeated `updateUIViewController` calls don't stack duplicates.
    /// The handler flips a SwiftUI `@Binding` rather than calling
    /// `AVPlayerViewController.present(...)` directly — UIKit modal presentation
    /// from inside an Info-tab action is unreliable on tvOS, so the parent
    /// SwiftUI view owns the sheet instead.
    private func ensureEpisodeDescriptionInfoAction(on playerViewController: AVPlayerViewController) {
        let identifier = Self.episodeDescriptionActionIdentifier
        let current = playerViewController.infoViewActions ?? []
        guard !current.contains(where: { $0.identifier == identifier }) else { return }

        let action = UIAction(
            title: L10n.tvEpisodeShowNotesTitle,
            image: UIImage(systemName: "info.circle"),
            identifier: identifier
        ) { _ in
            isShowingDescription = true
        }
        // Prepend so "Episode details" appears above the system's default
        // "Play from Beginning" entry in the Info tab.
        playerViewController.infoViewActions = [action] + current
    }

    private func createMetadataItems() -> [AVMetadataItem] {
        var items = [
            makeMetadataItem(.commonIdentifierTitle, value: model.displayTitle),
            makeMetadataItem(.iTunesMetadataTrackSubTitle, value: model.displaySubTitle),
            makeMetadataItem(.commonIdentifierDescription, value: model.displayTitle)
        ]

        if let imageData = model.displayImageData {
            items.append(makeMetadataItem(.commonIdentifierArtwork, value: imageData))
        }

        return items
    }

    private func makePlaybackSpeedMenu() -> UIMenu {
        let speeds = Array(stride(from: SharedConstants.PlaybackEffects.minimumPlaybackSpeed,
                                  through: model.maxPlaybackSpeed,
                                  by: 0.1))
        let actions = speeds.map { speed in
            UIAction(
                title: String(format: "%.1fx", speed),
                state: speed == model.playbackSpeed ? .on : .off
            ) { action in
                model.playbackSpeed = speed
                AnalyticsPlaybackHelper.shared.currentSource = .player
                AnalyticsPlaybackHelper.shared.playbackSpeedChanged(to: speed)
                if let menu = action.sender as? UIMenu {
                    menu.children.compactMap { $0 as? UIAction }.forEach { $0.state = .off }
                }
                action.state = .on
                ToastManager.shared.show(L10n.tvPlayerPlaybackSpeedSet(String(format: "%.1fx", speed)))
            }
        }
        return UIMenu(
            title: L10n.tvPlayerPlaybackSpeed,
            image: UIImage(systemName: "gauge.with.dots.needle.33percent"),
            children: [UIMenu(title: "", options: [.displayInline, .singleSelection], children: actions)]
        )
    }

    private func makePlaybackEffectsMenu() -> UIMenu? {
        var sections: [UIMenu] = []

        if model.isVolumeBoostAvailable {
            let volumeBoostOff = UIAction(title: L10n.off, state: model.volumeBoost ? .off : .on) { _ in
                ToastManager.shared.show(L10n.tvPlayerVolumeBoostOff)
                model.volumeBoost = false
                AnalyticsPlaybackHelper.shared.currentSource = .player
                AnalyticsPlaybackHelper.shared.volumeBoostToggled(enabled: false)
            }
            let volumeBoostOn = UIAction(title: L10n.on, state: model.volumeBoost ? .on : .off) { _ in
                ToastManager.shared.show(L10n.tvPlayerVolumeBoostOn)
                model.volumeBoost = true
                AnalyticsPlaybackHelper.shared.currentSource = .player
                AnalyticsPlaybackHelper.shared.volumeBoostToggled(enabled: true)
            }
            let volumeBoostSection = UIMenu(
                title: L10n.tvPlayerVolumeBoost,
                options: [.displayInline, .singleSelection],
                children: [volumeBoostOff, volumeBoostOn]
            )
            sections.append(volumeBoostSection)
        }

        if  model.isTrimSilenceAvailable {
            let trimActions = TrimSilenceAmount.allCases.map { option in
                UIAction(title: option.description, state: model.trimSilence == option ? .on : .off) { _ in
                    model.trimSilence = option
                    AnalyticsPlaybackHelper.shared.currentSource = .player
                    AnalyticsPlaybackHelper.shared.trimSilenceAmountChanged(amount: option)
                    ToastManager.shared.show(L10n.tvPlayerTrimSilenceSet(option.description))
                }
            }

            let trimSection = UIMenu(
                title: L10n.tvPlayerTrimSilence,
                options: [.displayInline, .singleSelection],
                children: trimActions
            )
            sections.append(trimSection)
        }
        if sections.isEmpty {
            return nil
        } else {
            return UIMenu(
                title: L10n.tvPlayerPlaybackEffects,
                image: UIImage(systemName: "speaker.wave.3"),
                children: sections
            )
        }
    }

    /// Builds the ellipsis menu sitting alongside the playback-speed and
    /// playback-effects round buttons on the transport bar. Shows the
    /// played/unplayed and archive/unarchive entries that match the current
    /// episode's state, so the action label always reflects what the tap
    /// will do.
    private func makeEpisodeActionsMenu() -> UIMenu {
        // Mark Played and Archive both stop playback as a side effect of
        // `EpisodeManager.markAsPlayed` / `archiveEpisode`, so the
        // destructive sides defer to the parent SwiftUI view's `.alert`
        // for a confirmation step before running. The reverses are direct.
        let playToggle: UIAction
        if model.isPlayed {
            playToggle = UIAction(
                title: L10n.markUnplayedShort,
                image: UIImage(systemName: "circle")
            ) { _ in
                requireAccount {
                    AnalyticsEpisodeHelper.shared.currentSource = .player
                    model.markAsUnplayed()
                    ToastManager.shared.show(L10n.markUnplayedShort)
                }
            }
        } else {
            playToggle = UIAction(
                title: L10n.markPlayedShort,
                image: UIImage(systemName: "checkmark.circle")
            ) { _ in
                requireAccount {
                    isShowingMarkAsPlayedConfirmation = true
                }
            }
        }

        var children: [UIAction] = [playToggle]

        if model.canArchive {
            let archiveToggle: UIAction
            if model.isArchived {
                archiveToggle = UIAction(
                    title: L10n.unarchive,
                    image: UIImage(systemName: "tray.and.arrow.up")
                ) { _ in
                    requireAccount {
                        AnalyticsEpisodeHelper.shared.currentSource = .player
                        model.unarchive()
                        ToastManager.shared.show(L10n.unarchive)
                    }
                }
            } else {
                archiveToggle = UIAction(
                    title: L10n.archive,
                    image: UIImage(systemName: "archivebox")
                ) { _ in
                    requireAccount {
                        isShowingArchiveConfirmation = true
                    }
                }
            }
            children.append(archiveToggle)
        }

        if model.podcastUuid != nil {
            let goToPodcast = UIAction(
                title: L10n.goToPodcast,
                image: UIImage(systemName: "mic.fill")
            ) { _ in
                isShowingPodcast = true
            }
            children.append(goToPodcast)
        }

        // No title: the ellipsis icon already conveys "more", and the
        // action labels (Mark Played / Archive) speak for themselves.
        return UIMenu(
            title: L10n.accessibilityMoreActions,
            image: UIImage(systemName: "ellipsis"),
            children: children
        )
    }

    private func makeMetadataItem(_ identifier: AVMetadataIdentifier, value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }
}
