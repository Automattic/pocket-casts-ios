import UIKit
import SwiftUI

/// An Activity Provider used for the share sheet
///
/// Given stories assets are generated in the main thread
/// and when the user taps "Share" we use this provider to
/// avoid blocking the main thread and the share sheet
/// having a delay when appearing.
class StoryShareableProvider: UIActivityItemProvider {
    static var shared: StoryShareableProvider = StoryShareableProvider()

    var generatedItem: Any?

    var generatedItemURL: Any?

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
            if activityType?.rawValue.contains("instagram") == true {
                generatedItemURL ?? NSURL()
            } else {
                generatedItem ?? UIImage()
            }
        }
    }

    // This method is called when the share sheet appeared
    // So we can go ahead and snapshot the view
    @MainActor
    func snapshot(viewModifier: (AnyView) -> some View) {
        guard let view else {
            return
        }

        let snapshot = AnyView(view)
        .modify(viewModifier)
        .environment(\.renderForSharing, true)
        .frame(width: 370, height: 800)
        .snapshot()

        let snapshotURL = save(snapshot: snapshot)
        generatedItemURL = snapshotURL
        generatedItem = snapshot
        self.view = nil
    }

    private func save(snapshot: UIImage) -> URL? {
        guard let imageData = snapshot.pngData() else { return nil }

        let tempDir = FileManager.default.temporaryDirectory
        let uuid = UUID().uuidString
        let url = tempDir.appendingPathComponent("pocket-casts-share-image-\(uuid).png")

        do {
           try imageData.write(to: url)
        } catch {
            return nil
        }

        return url
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
