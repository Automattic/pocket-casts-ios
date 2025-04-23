import UIKit
import SwiftUI
import PocketCastsDataModel

struct PodcastTableCellView: View {
    let podcast: Podcast

    var body: some View {
        PodcastImage(uuid: podcast.uuid)

        Text(podcast.title ?? "")
            .font(style: .body)
    }
}

final class PodcastTableViewCell: UITableViewCell {

    static var reuseIdentifier: String = "PodcastTableViewCell"

    override func prepareForReuse() {
        super.prepareForReuse()

        contentConfiguration = nil
    }

    func configure(with podcast: Podcast) {
        if #available(iOS 16.0, *) {
            self.contentConfiguration = UIHostingConfiguration {
                PodcastTableCellView(podcast: podcast)
            }
        } else {
            let view = PodcastTableCellView(podcast: podcast)
            let uiView = view.environmentObject(Theme.sharedTheme).uiView
            contentView.addSubview(uiView)
        }
    }
}
