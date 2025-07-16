import UIKit
import SwiftUI
import PocketCastsDataModel

class PlaylistCell: ThemeableCell {
    static let reuseIdentifier = "PlaylistCell"

    func configure(playlist: EpisodeFilter, resetConfiguration: Bool) {
        if !resetConfiguration {
            return
        }
        contentConfiguration = UIHostingConfiguration {
            PlaylistCellView(viewModel: PlaylistCellViewModel(playlist: playlist))
                .environmentObject(Theme.sharedTheme)
                .frame(maxWidth: .infinity, minHeight: 81.0, alignment: .topLeading)
        }
        .margins(.horizontal, 0)
        .margins(.vertical, 0)
    }
}
