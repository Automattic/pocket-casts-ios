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
    var firstTime = true
    init(podcast: Podcast, vc: PodcastViewController) {
        self.podcast = podcast
        self.viewController = vc
        self.viewModel = PodcastHeaderViewModel(podcast: podcast, delegate: self.viewController)
        super.init(style: .default, reuseIdentifier: "PodcastHeaderCell")
        commonSetup()
    }

    var calculatedHeight: CGFloat?

    var rowHeight: CGFloat {
        return calculatedHeight ?? UITableView.automaticDimension
    }

    func commonSetup() {
        guard let viewController = self.viewController else { return }
        self.backgroundColor = .clear
        self.selectionStyle = .none
        configureCellFromSwiftUIView(cell: self, viewController: viewController, rootView: {
            ContentSizeGeometryReader { proxy in
                PodcastHeaderView(viewModel: self.viewModel)
                    .setupDefaultEnvironment()
                    .ignoresSafeArea()//Needs to be done in order to allow expansion of the view to navigation area when scrolling up
            } contentSizeUpdated: { [weak self] size in
                guard let self = self else { return }
                calculatedHeight = size.height
                if firstTime {
                    firstTime = false
                    viewController.reloadData()
                } else {
                    // the following code allows the table to refresh the row height in a animated way
                    viewController.tableView().beginUpdates()
                    viewController.tableView().endUpdates()
                }

            }
        })
    }

    func configureCellFromSwiftUIView<Content: View>(cell: UITableViewCell, viewController: UIViewController, @ViewBuilder rootView: @escaping () -> Content) {
        let swiftUICellViewController = UIHostingController(rootView: rootView())
        swiftUICellViewController.view.backgroundColor = .clear
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.layoutIfNeeded()
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.contentView.clipsToBounds = true
        viewController.addChild(swiftUICellViewController)
        cell.contentView.addSubview(swiftUICellViewController.view)
        swiftUICellViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cell.contentView.topAnchor.constraint(equalTo: swiftUICellViewController.view.topAnchor),
            cell.contentView.bottomAnchor.constraint(equalTo: swiftUICellViewController.view.bottomAnchor),
            cell.contentView.leftAnchor.constraint(equalTo: swiftUICellViewController.view.leftAnchor),
            cell.contentView.rightAnchor.constraint(equalTo: swiftUICellViewController.view.rightAnchor),
        ])
        swiftUICellViewController.didMove(toParent: viewController)
        swiftUICellViewController.view.layoutIfNeeded()
    }
}
