import UIKit
import SwiftUI
import PocketCastsDataModel

class PlaylistCell: ThemeableCell {
    static let reuseIdentifier = "PlaylistCell"

    override func prepareForReuse() {
        super.prepareForReuse()
        contentConfiguration = nil
    }

    func configure(playlist: EpisodeFilter) {
        contentConfiguration = UIHostingConfiguration {
            PlaylistCellView(viewModel: PlaylistCellViewModel(playlist: playlist))
                .environmentObject(Theme.sharedTheme)
                .frame(maxWidth: .infinity, minHeight: 81.0, alignment: .topLeading)
        }
        .margins(.horizontal, 0)
        .margins(.vertical, 0)
    }
}
