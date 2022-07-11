import SwiftUI

protocol Restorable {
    func restoreName() -> String?
    func restoreContext() -> [String: Any]?
}

extension View {
    func restorable(_ type: WatchInterfaceType) -> some View {
        onAppear {
            UserDefaults.standard.set(type.rawValue, forKey: WatchConstants.UserDefaults.lastPage)
        }
    }
}
