import Combine

/// Model that publishes the progress of Stories
///
/// This is a singleton because it's shared between different views.
class StoriesProgressModel: ObservableObject {
    @Published var progress: Double

    static let shared = StoriesProgressModel()

    private init() {
        progress = 0
    }
}
