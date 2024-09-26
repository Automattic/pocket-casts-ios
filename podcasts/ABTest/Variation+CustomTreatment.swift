import AutomatticTracks

extension Variation {
    enum CustomTreatment: String, Equatable {

        //pocketcasts_paywall_upgrade_ios_ab_test
        case featuresTreatment = "features_treatment"
        case reviewsTreatment = "reviews_treatment"
    }

    func getCustomTreatment() -> CustomTreatment? {
        switch self {
        case .customTreatment(let name):
            return CustomTreatment(rawValue: name)
        default:
            return nil
        }
    }
}
