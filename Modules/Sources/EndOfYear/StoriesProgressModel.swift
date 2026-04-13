import Combine

/// Model that publishes the progress of Stories
///
/// This is a singleton because it's shared between different views.
public class StoriesProgressModel: ObservableObject {
    @Published public var progress: Double

    public static let shared = StoriesProgressModel()

    private init() {
        progress = 0
    }
}
