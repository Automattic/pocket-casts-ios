import Foundation
import PocketCastsDataModel

/// Build the list of stories for End of Year alongside the data
class EndOfYearStoriesBuilder {
    private let dataManager: DataManager

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
    }

    // Call this method to build the list of stories and the data provider
    func build() async {

    }
}
