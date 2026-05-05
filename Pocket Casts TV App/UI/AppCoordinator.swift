import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

@Observable
class AppCoordinator {
    enum State {
        case loading
        case welcome
        case browsing
        case signedIn
        case userSync
    }

    var state: State = .loading

    func load() async {
        let _ = DataManager.sharedManager
        state = .welcome
    }
}
