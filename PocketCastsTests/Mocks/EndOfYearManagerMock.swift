import Foundation
import FMDB

@testable import PocketCastsDataModel

class EndOfYearManagerMock: EndOfYearDataManager {
    var listeningTimeToReturn: Double = 0

    var listenedCategoriesToReturn: [ListenedCategory] = []

    var listenedNumbersToReturn: ListenedNumbers?

    override func listeningTime(dbQueue: FMDatabaseQueue) -> Double? {
        return listeningTimeToReturn
    }

    override func listenedCategories(dbQueue: FMDatabaseQueue) -> [ListenedCategory] {
        return listenedCategoriesToReturn
    }

    override func listenedNumbers(dbQueue: FMDatabaseQueue) -> ListenedNumbers {
        return listenedNumbersToReturn!
    }
}
