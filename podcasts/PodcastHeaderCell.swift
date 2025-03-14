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
    let viewController: PodcastViewController

    init(podcast: Podcast, vc: PodcastViewController) {
        self.podcast = podcast
        self.viewController = vc
        super.init(style: .default, reuseIdentifier: "PodcastHeaderCell")
        commonSetup()
    }

    var calculatedHeight: CGFloat?

    var rowHeight: CGFloat {
        return calculatedHeight ?? UITableView.automaticDimension
    }

    func commonSetup() {
        self.backgroundColor = .clear
        let viewModel = PodcastHeaderViewModel(podcast: podcast, delegate: self.viewController)
        if #available(iOS 16.0, *) {
            self.contentConfiguration = UIHostingConfiguration(content: {
                PodcastHeaderView(viewModel: viewModel).setupDefaultEnvironment()
            })
        } else {
            // Fallback on earlier versions
            configureCellFromSwiftUIView( cell: self, viewController: self.viewController, rootView: {
                    ContentSizeGeometryReader { proxy in
                        PodcastHeaderView(viewModel: viewModel).setupDefaultEnvironment().padding()
                    } contentSizeUpdated: { size in
                        self.calculatedHeight = size.height
                        self.setNeedsLayout()
                        self.viewController.tableView().reloadData()
                    }
            })
        }
    }

    func configureCellFromSwiftUIView<Content: View>(cell: UITableViewCell, viewController: UIViewController, @ViewBuilder rootView: @escaping () -> Content) {

        let swiftUICellViewController = UIHostingController(rootView: rootView())
        swiftUICellViewController.view.backgroundColor = .clear
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.layoutIfNeeded()
        cell.selectionStyle = UITableViewCell.SelectionStyle.none

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
