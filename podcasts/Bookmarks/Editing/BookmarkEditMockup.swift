import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

// MARK: - Preview using the real BookmarkEditTitleView with transcript

struct SmartBookmarkEditPreview: PreviewProvider {
    static var previews: some View {
        BookmarkEditTitleView(viewModel: {
            let vm = BookmarkEditViewModel(
                manager: .init(),
                bookmark: Self.previewBookmark(title: "The Senate voted on the Indiana...", time: 3600, created: .now),
                state: .adding,
                transcriptText: "The Senate voted on the Indiana safety bill as families battle for stronger protections. Critics argue the measure doesn't go far enough while supporters say it strikes the right balance."
            )
            vm.onEditTranscript = {}
            return vm
        }(), theme: .init(episode: nil)).setupDefaultEnvironment()
    }
}
