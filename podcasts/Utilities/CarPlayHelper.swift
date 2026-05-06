#if os(tvOS)
enum CarPlayHelper {
    static var isConnectedToCarPlay: Bool {
        return false
    }
}
#else
import CarPlay

enum CarPlayHelper {
    static var isConnectedToCarPlay: Bool {
        UIApplication.shared.connectedScenes.contains(where: {
            $0 is CPTemplateApplicationScene
        })
    }
}
#endif
