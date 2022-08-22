
import Foundation

class FunnyTimeConverter {
    static let timeUnits = FunnyTimeUnit.allCases
    class func timeSecsToFunnyText(_ timeInSeconds: Double) -> String {
        // don't bother if the listening time is less than 1 minute
        if timeInSeconds < 60 {
            return L10n.Localizable.funnyTimeNotEnough
        }
        
        while true {
            let randomIndex = arc4random_uniform(UInt32(timeUnits.count))
            let unit = timeUnits[Int(randomIndex)]
            if unit.suitableFor(timeInSeconds) {
                return unit.funnyTextForSeconds(timeInSeconds)
            }
        }
    }
    
    enum FunnyTimeUnit: CaseIterable {
        case births
        case blinks
        case lightning
        case shedSkin
        case astronautSneezes
        case emails
        case tweets
        case farts
        case tiedShoes
        case balloonTravel
        case google
        case airplaneTakeoffs
        case phoneProduction

        var timesPerMinute: Double {
            switch self {
            case .births:
                return 250
            case .blinks:
                return 7
            case .lightning:
                return 360
            case .shedSkin:
                return 583
            case .astronautSneezes:
                return 0.00694
            case .emails:
                return 100_000_000
            case .tweets:
                return 121_527.77
            case .farts:
                return 0.0118
            case .tiedShoes:
                return 6
            case .balloonTravel:
                return 0.0002314
            case .google:
                return 2_400_000
            case .airplaneTakeoffs:
                return 212
            case .phoneProduction:
                return 44400
            }
        }

        func funnyTextForSeconds(_ seconds: Double) -> String {
            let minutes = seconds / 60
            let amount = floor(minutes * timesPerMinute)

            switch self {
            case .births:
                return L10n.Localizable.funnyTimeUnitBirths(amount.localized())
            case .blinks:
                return L10n.Localizable.funnyTimeUnitBlinks(amount.localized())
            case .lightning:
                return L10n.Localizable.funnyTimeUnitLightning(amount.localized())
            case .shedSkin:
                return L10n.Localizable.funnyTimeUnitShedSkin(amount.localized())
            case .astronautSneezes:
                return L10n.Localizable.funnyTimeUnitAstronautSneezes(amount.localized())
            case .emails:
                return L10n.Localizable.funnyTimeUnitEmails(amount.localized())
            case .tweets:
                return L10n.Localizable.funnyTimeUnitTweets(amount.localized())
            case .farts:
                return L10n.Localizable.funnyTimeUnitFarts(amount.localized())
            case .tiedShoes:
                return L10n.Localizable.funnyTimeUnitTiedShoes(amount.localized())
            case .balloonTravel:
                return L10n.Localizable.funnyTimeUnitBalloonTravel(amount.localized())
            case .google:
                return L10n.Localizable.funnyTimeUnitGoogle(amount.localized())
            case .airplaneTakeoffs:
                return L10n.Localizable.funnyTimeUnitAirplaneTakeoffs(amount.localized())
            case .phoneProduction:
                return L10n.Localizable.funnyTimeUnitPhoneProduction(amount.localized())
            }
        }
        
        func suitableFor(_ seconds: Double) -> Bool {
            let minutes = seconds / 60
            let amount = minutes * timesPerMinute
            
            return amount >= 1
        }
    }
}
