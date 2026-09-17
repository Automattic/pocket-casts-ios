import SwiftUI

@MainActor
protocol TranscriptExcerptViewModeling: ObservableObject {
    var loadingState: TranscriptExcerptLoadingState { get set }
    var isGeneratedTranscript: Bool { get }

    init(episodeUUID: String, podcastUUID: String, isGeneratedTranscript: Bool, tapAction: @escaping () -> Void)

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

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize = 16

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
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(theme.primaryIcon02)
                        .frame(width: iconSize, height: iconSize)
                }
                Text(L10n.viewTranscript)
                    .font(size: 15.0, style: .body, weight: .medium)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(theme.primaryText01)
                    .redacted(if: viewModel.loadingState == .loading)
                Spacer()
                Image("listview_arrow")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(theme.primaryIcon02)
                    .frame(width: iconSize/2, height: iconSize)
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

    convenience init(loadingState: TranscriptExcerptLoadingState, isGeneratedTranscript: Bool) {
        self.init(episodeUUID: "", podcastUUID: "", isGeneratedTranscript: isGeneratedTranscript, tapAction: {  })
        self.loadingState = loadingState
    }

    required init(episodeUUID: String, podcastUUID: String, isGeneratedTranscript: Bool, tapAction: () -> Void) {
        self.isGeneratedTranscript = isGeneratedTranscript
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
