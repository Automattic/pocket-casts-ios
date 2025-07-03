import SwiftUI

protocol TranscriptExcerptViewModeling: ObservableObject {
    var loadingState: TranscriptExcerptLoadingState { get set }
    var isGeneratedTranscript: Bool { get }

    init(episodeUUID: String, podcastUUID: String, isGeneratedTranscript: Bool, tapAction: @escaping () -> Void)

    func loadExcerptTranscript() async
    func excerptTapped()
    func trackViewAppear()
}

enum TranscriptExcerptLoadingState {
    case idle
    case loading
    case success
    case failure
}

class TranscriptExcerptViewModel: ObservableObject, TranscriptExcerptViewModeling {
    @Published var loadingState: TranscriptExcerptLoadingState = .success

    let isGeneratedTranscript: Bool
    private let manager: TranscriptManager
    private let tapAction: () -> Void
    private let episodeUUID: String
    private let podcastUUID: String

    required init(
        episodeUUID: String,
        podcastUUID: String,
        isGeneratedTranscript: Bool,
        tapAction: @escaping () -> Void
    ) {
        self.episodeUUID = episodeUUID
        self.podcastUUID = podcastUUID
        self.isGeneratedTranscript = isGeneratedTranscript
        self.tapAction = tapAction
        self.manager = TranscriptManager(episodeUUID: episodeUUID, podcastUUID: podcastUUID)
    }

    @discardableResult
    func loadTranscript() async throws -> TranscriptModel {
        try await manager.loadTranscript()
    }

    func loadExcerptTranscript() async {
        if case .loading = loadingState { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            loadingState = .loading
            do {
                try await loadTranscript()
                loadingState = .success
            } catch {
                loadingState = .failure
            }
        }
    }

    func excerptTapped() {
        guard loadingState == .success else { return }
        tapAction()
        track(.episodeDetailTranscriptCardTapped)
    }

    func trackViewAppear() {
        track(.episodeDetailTranscriptCardShown)
    }

    private func track(_ event: AnalyticsEvent) {
        Analytics.track(
            event,
            properties: [
                "episode_uuid": episodeUUID,
                "podcast_uuid": podcastUUID
            ]
        )
    }
}

struct TranscriptExcerptView<ViewModel: TranscriptExcerptViewModeling>: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.clear)
                .background(theme.primaryUi02Active)
                .cornerRadius(8.0)
                .shadow(
                    color: .black.opacity(0.2),
                    radius: 3, x: 0, y: 1
                )
                .frame(minHeight: 48.0)
            HStack(spacing: 12.0) {
                if viewModel.isGeneratedTranscript {
                    Image("generated_transcript")
                        .renderingMode(.template)
                        .foregroundStyle(theme.primaryIcon02)
                        .frame(width: 16, height: 16)
                }
                Text(L10n.viewTranscript)
                    .font(size: 15.0, style: .body, weight: .medium)
                    .foregroundStyle(theme.primaryText01)
                    .redacted(if: viewModel.loadingState == .loading)
                Spacer()
                Image("listview_arrow")
                    .renderingMode(.template)
                    .foregroundStyle(theme.primaryIcon02)
            }
            .padding(.horizontal, 16.0)
        }
        .padding(.horizontal, 16.0)
        .padding(.top, 16.0)
        .padding(.bottom, 14.0)
        .onAppear {
            viewModel.trackViewAppear()
        }
        .onTapGesture {
            viewModel.excerptTapped()
        }
    }
}

private class MockTranscriptExcerptViewModel: TranscriptExcerptViewModeling {
    @Published var loadingState: TranscriptExcerptLoadingState = .loading

    let isGeneratedTranscript: Bool

    private var _privateLoadingState: TranscriptExcerptLoadingState = .loading

    convenience init(loadingState: TranscriptExcerptLoadingState, isGeneratedTranscript: Bool) {
        self.init(episodeUUID: "", podcastUUID: "", isGeneratedTranscript: isGeneratedTranscript, tapAction: {  })
        self._privateLoadingState = loadingState
    }

    required init(episodeUUID: String, podcastUUID: String, isGeneratedTranscript: Bool, tapAction: () -> Void) {
        self.isGeneratedTranscript = isGeneratedTranscript
    }

    func loadExcerptTranscript() async {
        await MainActor.run {
            self.loadingState = _privateLoadingState

            switch self.loadingState {
            case .idle, .loading:
                break
            case .failure, .success:
                break
            }
        }
    }

    func excerptTapped() {}
    func trackViewAppear() {}
}

#Preview {
    TranscriptExcerptView(
        viewModel: MockTranscriptExcerptViewModel(
            loadingState: .loading,
            isGeneratedTranscript: true)
    )
    .environmentObject(Theme(previewTheme: .light))
    .frame(width: 375, height: 78)
}

#Preview {
    TranscriptExcerptView(
        viewModel: MockTranscriptExcerptViewModel(
            loadingState: .success,
            isGeneratedTranscript: true)
    )
    .environmentObject(Theme(previewTheme: .light))
    .frame(width: 375, height: 78)
}

#Preview {
    TranscriptExcerptView(
        viewModel: MockTranscriptExcerptViewModel(
            loadingState: .success,
            isGeneratedTranscript: false)
    )
    .environmentObject(Theme(previewTheme: .light))
    .frame(width: 375, height: 78)
}
