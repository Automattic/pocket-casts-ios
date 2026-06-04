import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI

struct BookmarkDetailView: View {
    @EnvironmentObject private var theme: Theme
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var transcriptText: String?
    @State private var transcriptStartTime: TimeInterval?
    @State private var transcriptEndTime: TimeInterval?

    let bookmark: Bookmark
    let episode: BaseEpisode?
    let onPlay: () -> Void
    var isModal: Bool = false

    private let bookmarkLookup: () -> Bookmark?
    private let editAction: ((@escaping () -> Void) -> Void)?

    init(bookmark: Bookmark,
         episode: BaseEpisode?,
         onPlay: @escaping () -> Void,
         onEdit: ((@escaping () -> Void) -> Void)? = nil,
         isModal: Bool = false,
         bookmarkLookup: ((String) -> Bookmark?)? = nil) {
        self.bookmark = bookmark
        self._title = State(initialValue: bookmark.title)
        self._transcriptText = State(initialValue: bookmark.transcriptText)
        self._transcriptStartTime = State(initialValue: bookmark.transcriptStartTime)
        self._transcriptEndTime = State(initialValue: bookmark.transcriptEndTime)
        self.episode = episode
        self.onPlay = onPlay
        self.editAction = onEdit
        self.isModal = isModal
        let uuid = bookmark.uuid
        self.bookmarkLookup = { bookmarkLookup?(uuid) }
    }

    private var podcastTitle: String? {
        if let podcastUuid = bookmark.podcastUuid {
            return DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true)?.title
        }
        return nil
    }

    private func refreshFromDatabase() {
        if let updated = bookmarkLookup() {
            title = updated.title
            transcriptText = updated.transcriptText
            transcriptStartTime = updated.transcriptStartTime
            transcriptEndTime = updated.transcriptEndTime
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                headerView
                Divider()
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    titleSection
                    if let transcriptText {
                        transcriptSection(transcriptText)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 12)
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 12)
                }
            )
        }
        .background(AppTheme.color(for: .primaryUi01, theme: theme))
        .navigationTitle(L10n.bookmarkDefaultTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isModal {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
                    }
                }
            }
            if editAction != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editAction? {
                            refreshFromDatabase()
                        }
                    } label: {
                        Image("folder-edit")
                            .renderingMode(.template)
                            .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            if let episode {
                EpisodeImage(episode: episode)
                    .frame(width: 64, height: 64)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                if let podcastTitle {
                    Text(podcastTitle)
                        .font(style: .caption, weight: .semibold)
                        .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
                        .lineLimit(1)
                }

                if let episodeTitle = episode?.title {
                    Text(episodeTitle)
                        .font(style: .subheadline, weight: .medium)
                        .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))
                        .lineLimit(2)
                }
            }

            Spacer()

            playButton
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(size: 22, style: .title2, weight: .bold)
                .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))
        }
    }

    // MARK: - Transcript

    private func transcriptSection(_ text: String) -> some View {
        let paragraphs = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        return VStack(alignment: .leading, spacing: 12) {
            if let startTime = transcriptStartTime,
               let endTime = transcriptEndTime {
                let formattedStart = TimeFormatter.shared.playTimeFormat(time: startTime)
                let formattedEnd = TimeFormatter.shared.playTimeFormat(time: endTime)
                Text("\(formattedStart) – \(formattedEnd)")
                    .font(style: .caption, weight: .semibold)
                    .foregroundStyle(AppTheme.color(for: .primaryText02, theme: theme))
            }

            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(style: .body)
                    .foregroundStyle(AppTheme.color(for: .primaryText01, theme: theme))
            }
        }
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Play Button

    private var playButton: some View {
        let timestamp = TimeFormatter.shared.playTimeFormat(time: bookmark.time)
        return Button {
            onPlay()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "play.fill")
                    .font(.system(size: 11))
                Text(timestamp)
                    .font(style: .footnote, weight: .semibold)
            }
            .foregroundStyle(AppTheme.color(for: .primaryInteractive02, theme: theme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppTheme.color(for: .primaryInteractive01, theme: theme))
            .clipShape(Capsule())
        }
    }
}
