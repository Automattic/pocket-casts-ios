import UIKit
import SwiftUI
import PocketCastsUtils

/// An Activity Provider used for the share sheet
///
/// Given stories assets are generated in the main thread
/// and when the user taps "Share" we use this provider to
/// avoid blocking the main thread and the share sheet
/// having a delay when appearing.
public class StoryShareableProvider: UIActivityItemProvider {
    public static var shared: StoryShareableProvider = StoryShareableProvider()

    public var generatedItem: Any?

    public var generatedItemURL: Any?

    public var view: AnyView?

    public static func new(_ view: AnyView) -> StoryShareableProvider {
        shared = StoryShareableProvider()
        shared.view = view
        return shared
    }

    public init() {
        super.init(placeholderItem: UIImage())
    }

    override public var item: Any {
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
    public func snapshot(viewModifier: (AnyView) -> some View) {
        guard let view else {
            return
        }

        let snapshot = AnyView(view)
        .modify(viewModifier)
        .environment(\.renderForSharing, true)
        .frame(width: 450, height: 800)
        .ignoresSafeArea()
        .snapshotUIKit()

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
    public var renderForSharing: Bool {
        get { self[RenderSharingKey.self] }
        set { self[RenderSharingKey.self] = newValue }
    }

    private struct RenderSharingKey: EnvironmentKey {
        static let defaultValue: Bool = false
    }
}
