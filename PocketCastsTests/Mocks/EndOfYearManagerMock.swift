import Foundation
import FMDB

@testable import PocketCastsDataModel

class EndOfYearManagerMock: EndOfYearDataManager {
    var listeningTimeToReturn: Double = 0

    var listenedCategoriesToReturn: [ListenedCategory] = []

    override func listeningTime(dbQueue: FMDatabaseQueue) -> Double? {
        return listeningTimeToReturn
    }

    override func listenedCategories(dbQueue: FMDatabaseQueue) -> [ListenedCategory] {
        return listenedCategoriesToReturn
    }
}
