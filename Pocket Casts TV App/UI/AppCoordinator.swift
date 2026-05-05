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
        // Ensure database and tables are setup before we go forward
        let _ = DataManager.sharedManager

        setupCredentials()
        
        state = .welcome
    }

    private func setupCredentials() {
        ServerCredentials.sharing = ApiCredentials.sharingServerSecret
    }
}
