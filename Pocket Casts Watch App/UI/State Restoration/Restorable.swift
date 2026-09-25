import SwiftUI

extension View {
    func restorable(_ type: WatchInterfaceType) -> some View {
        onAppear {
            UserDefaults.standard.set(type.rawValue, forKey: WatchConstants.UserDefaults.lastPage)
        }
    }
}
