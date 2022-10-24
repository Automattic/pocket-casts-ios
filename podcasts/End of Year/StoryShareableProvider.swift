import UIKit

/// An Activity Provider used for the share sheet
///
/// Given stories assets are generated in the main thread
/// and when the user taps "Share" we use this provider to
/// avoid blocking the main thread and the share sheet
/// having a delay when appearing.
class StoryShareableProvider: UIActivityItemProvider {
    static var generatedItem: Any?

    init() {
        super.init(placeholderItem: UIImage())
    }

    override var item: Any {
        get {
            Self.generatedItem ?? UIImage()
        }
    }
}
