#if DEBUG

import PocketCastsServer
import SwiftUI
import UIKit

/// Hosts a Discover section the way `DiscoverCollectionViewController` does — handed a delegate,
/// then populated — and sizes it the way the self-sizing collection view cell does.
///
/// Build `section` with its `serverHandler` pointed at a ``PreviewDiscoverServerHandler`` so it
/// renders canned data instead of hitting the network.
struct DiscoverSectionPreview: View {
    let section: UIViewController & DiscoverSummaryProtocol
    let item: DiscoverItem

    var region = "us"
    var category: DiscoverCategory?
    var delegate = PreviewDiscoverDelegate()

    /// Fixes the section's height. Leave it `nil` to let the section size itself.
    var height: CGFloat?

    /// Sections hand their loaded data to the UI over one or more main-queue hops. Bumping this
    /// once the dust has settled re-runs the sizing pass, so sections whose height comes from their
    /// data end up the right size in the canvas.
    @State private var settleCount = 0

    var body: some View {
        VStack(spacing: 0) {
            SectionHost(
                section: section,
                item: item,
                region: region,
                category: category,
                delegate: delegate,
                height: height,
                settleCount: settleCount
            )
            .frame(height: height)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.color(for: .primaryUi02, theme: Theme.sharedTheme))
        .environmentObject(Theme.sharedTheme)
        .task {
            try? await Task.sleep(for: .milliseconds(250))
            settleCount += 1
        }
    }
}

private struct SectionHost: UIViewControllerRepresentable {
    let section: UIViewController & DiscoverSummaryProtocol
    let item: DiscoverItem
    let region: String
    let category: DiscoverCategory?
    let delegate: PreviewDiscoverDelegate
    let height: CGFloat?
    let settleCount: Int

    func makeUIViewController(context: Context) -> UIViewController {
        // A parent keeps the section in a real containment hierarchy, so appearance callbacks and
        // trait propagation behave as they do inside the Discover collection view.
        let parent = UIViewController()

        section.registerDiscoverDelegate(delegate)

        parent.addChild(section)
        parent.view.addSubview(section.view)
        section.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            section.view.topAnchor.constraint(equalTo: parent.view.topAnchor),
            section.view.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
            section.view.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor),
            section.view.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor)
        ])
        section.didMove(toParent: parent)

        section.populateFrom(item: item, region: region, category: category)
        return parent
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        uiViewController.view.setNeedsLayout()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiViewController: UIViewController, context: Context) -> CGSize? {
        guard height == nil else { return nil }

        let width = proposal.width ?? UIScreen.main.bounds.width
        // Several sections derive their height from their own width, so give them one to measure
        // against before asking — the collection view cell they normally live in has already been
        // laid out by the time it asks for a fitting size.
        uiViewController.view.frame = CGRect(x: 0, y: 0, width: width, height: uiViewController.view.frame.height)
        uiViewController.view.layoutIfNeeded()
        let fitting = uiViewController.view.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: width, height: fitting.height)
    }
}

#endif
