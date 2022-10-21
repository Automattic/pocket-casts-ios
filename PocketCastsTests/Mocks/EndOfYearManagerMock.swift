import Foundation
import FMDB

@testable import PocketCastsDataModel

class EndOfYearManagerMock: EndOfYearDataManager {
    var listeningTimeToReturn: Double = 0

    override func listeningTime(dbQueue: FMDatabaseQueue) -> Double? {
        return listeningTimeToReturn
    }
}
