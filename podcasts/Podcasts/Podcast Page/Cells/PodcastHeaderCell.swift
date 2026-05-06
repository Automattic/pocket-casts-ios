import Foundation
import SwiftUI
import UIKit
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class PodcastHeaderCell: UITableViewCell {

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let podcast: Podcast
    weak var viewController: PodcastViewController?
    let viewModel: PodcastHeaderViewModel

    init(podcast: Podcast, vc: PodcastViewController) {
        self.podcast = podcast
        self.viewController = vc
        self.viewModel = PodcastHeaderViewModel(podcast: podcast, delegate: self.viewController)
        super.init(style: .default, reuseIdentifier: "PodcastHeaderCell")
        commonSetup()
    }

    func commonSetup() {
        backgroundColor = .clear
        selectionStyle = .none

        contentConfiguration = UIHostingConfiguration {
            PodcastHeaderView(viewModel: self.viewModel)
                    .setupDefaultEnvironment()
        }
        .margins(.horizontal, 0)
        .margins(.vertical, 0)
        .background(.clear)
    }
}
