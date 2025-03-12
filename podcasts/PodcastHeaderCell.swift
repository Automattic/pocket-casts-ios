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

    func commonSetup() {
        self.backgroundColor = .clear
        let viewModel = PodcastHeaderViewModel(podcast: podcast, delegate: self.viewController)
        if #available(iOS 16.0, *) {
            self.contentConfiguration = UIHostingConfiguration(content: {
                PodcastHeaderView(viewModel: viewModel).setupDefaultEnvironment()
            }
            )
        } else {
            // Fallback on earlier versions
            configureCellFromSwiftUIView(cell: self, viewController: self.viewController, rootView: PodcastHeaderView(viewModel: viewModel).setupDefaultEnvironment().padding())
        }
    }

    func configureCellFromSwiftUIView(cell: UITableViewCell, viewController: UIViewController, rootView: some View) {

        let swiftUICellViewController = UIHostingController(rootView: rootView)
        swiftUICellViewController.view.backgroundColor = .clear
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.layoutIfNeeded()
        cell.selectionStyle = UITableViewCell.SelectionStyle.none

        viewController.addChild(swiftUICellViewController)
        cell.contentView.addSubview(swiftUICellViewController.view)
        swiftUICellViewController.view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: cell.contentView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 0.0))
        cell.contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: cell.contentView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: 0.0))
        cell.contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: cell.contentView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0.0))
        cell.contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: cell.contentView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0.0))

        swiftUICellViewController.didMove(toParent: viewController)
        swiftUICellViewController.view.layoutIfNeeded()

    }
}
