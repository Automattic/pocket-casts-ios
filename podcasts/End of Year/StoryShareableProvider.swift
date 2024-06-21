import UIKit
import SwiftUI

/// An Activity Provider used for the share sheet
///
/// Given stories assets are generated in the main thread
/// and when the user taps "Share" we use this provider to
/// avoid blocking the main thread and the share sheet
/// having a delay when appearing.
class StoryShareableProvider: UIActivityItemProvider {
    static var shared: StoryShareableProvider!

    var generatedItem: Any?

    var view: AnyView?

    static func new(_ view: AnyView) -> StoryShareableProvider {
        shared = StoryShareableProvider()
        shared.view = view
        return shared
    }

    init() {
        super.init(placeholderItem: UIImage())
    }

    override var item: Any {
        get {
            generatedItem ?? UIImage()
        }
    }

    // This method is called when the share sheet appeared
    // So we can go ahead and snapshot the view
    @MainActor
    func snapshot() {
        guard let view else {
            return
        }

        let snapshot = StoryViewContainer {
            AnyView(view)
        }
        .environment(\.renderForSharing, true)
        .frame(width: 370, height: 658)
        .snapshot()

        generatedItem = snapshot
        self.view = nil
    }
}

extension EnvironmentValues {
    var renderForSharing: Bool {
        get { self[RenderSharingKey.self] }
        set { self[RenderSharingKey.self] = newValue }
    }

    private struct RenderSharingKey: EnvironmentKey {
        static let defaultValue: Bool = false
    }
}
