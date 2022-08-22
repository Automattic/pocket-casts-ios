import Foundation

public extension String {
    /// This allows us to split a strong and localize the first instance. This is particularly helpful with Podcast Categories.
    func localized(seperatingWith seperator: (Character) throws -> Bool) -> String? {
        if let substring = try? split(whereSeparator: seperator).first {
            return String(substring).localized
        }
        else {
            return localized
        }
    }

    func localized(with args: CVarArg...) -> String? {
        switch lowercased() {
        case "popular in [regionname]":
            return L10n.Localizable.discoverPopularIn(args[0])
        default:
            return self
        }
    }

    /// This contains a list of strings that can come from the server. This methid provides a helper to quickly lookup the localized versions.
    var localized: String {
        switch lowercased() {
        case "featured":
            return L10n.Localizable.discoverFeatured

        // Discover Card Titles
        case "browse by category":
            return L10n.Localizable.discoverBrowseByCategory
        case "popular":
            return L10n.Localizable.discoverPopular
        case "trending":
            return L10n.Localizable.discoverTrending

        // Categories
        case "arts":
            return L10n.Localizable.discoverBrowseByCategoryArt
        case "business":
            return L10n.Localizable.discoverBrowseByCategoryBusiness
        case "comedy":
            return L10n.Localizable.discoverBrowseByCategoryComedy
        case "education":
            return L10n.Localizable.discoverBrowseByCategoryEducation
        case "fiction":
            return L10n.Localizable.discoverBrowseByCategoryFiction
        case "games & hobbies":
            return L10n.Localizable.discoverBrowseByCategoryGamesAndHobbies
        case "government":
            return L10n.Localizable.discoverBrowseByCategoryGovernment
        case "government & organizations":
            return L10n.Localizable.discoverBrowseByCategoryGovernmentAndOrganizations
        case "health":
            return L10n.Localizable.discoverBrowseByCategoryHealth
        case "health & fitness":
            return L10n.Localizable.discoverBrowseByCategoryHealthAndFitness
        case "history":
            return L10n.Localizable.discoverBrowseByCategoryHistory
        case "kids & family":
            return L10n.Localizable.discoverBrowseByCategoryKidsAndFamily
        case "leisure":
            return L10n.Localizable.discoverBrowseByCategoryLeisure
        case "music":
            return L10n.Localizable.discoverBrowseByCategoryMusic
        case "news & politics":
            return L10n.Localizable.discoverBrowseByCategoryNewsAndPolitics
        case "news":
            return L10n.Localizable.discoverBrowseByCategoryNews
        case "religion & spirituality":
            return L10n.Localizable.discoverBrowseByCategoryReligionAndSpirituality
        case "science":
            return L10n.Localizable.discoverBrowseByCategoryScience
        case "science & medicine":
            return L10n.Localizable.discoverBrowseByCategoryScienceAndMedicine
        case "society":
            return L10n.Localizable.discoverBrowseByCategorySociety
        case "society & culture":
            return L10n.Localizable.discoverBrowseByCategorySocietyAndCulture
        case "sports":
            return L10n.Localizable.discoverBrowseByCategorySports
        case "sports & recreation":
            return L10n.Localizable.discoverBrowseByCategorySportsAndRecreation
        case "technology":
            return L10n.Localizable.discoverBrowseByCategoryTechnology
        case "true crime":
            return L10n.Localizable.discoverBrowseByCategoryTrueCrime
        case "tv & film":
            return L10n.Localizable.discoverBrowseByCategoryTvAndFilm

        // Regions
        case "australia":
            return L10n.Localizable.discoverRegionAustralia
        case "austria":
            return L10n.Localizable.discoverRegionAustria
        case "belgium":
            return L10n.Localizable.discoverRegionBelgium
        case "brazil":
            return L10n.Localizable.discoverRegionBrazil
        case "canada":
            return L10n.Localizable.discoverRegionCanada
        case "china":
            return L10n.Localizable.discoverRegionChina
        case "czechia":
            return L10n.Localizable.discoverRegionCzechia
        case "denmark":
            return L10n.Localizable.discoverRegionDenmark
        case "finland":
            return L10n.Localizable.discoverRegionFinland
        case "france":
            return L10n.Localizable.discoverRegionFrance
        case "germany":
            return L10n.Localizable.discoverRegionGermany
        case "hong kong":
            return L10n.Localizable.discoverRegionHongKong
        case "india":
            return L10n.Localizable.discoverRegionIndia
        case "ireland":
            return L10n.Localizable.discoverRegionIreland
        case "israel":
            return L10n.Localizable.discoverRegionIsrael
        case "italy":
            return L10n.Localizable.discoverRegionItaly
        case "japan":
            return L10n.Localizable.discoverRegionJapan
        case "mexico":
            return L10n.Localizable.discoverRegionMexico
        case "netherlands":
            return L10n.Localizable.discoverRegionNetherlands
        case "new zealand":
            return L10n.Localizable.discoverRegionNewZealand
        case "norway":
            return L10n.Localizable.discoverRegionNorway
        case "philippines":
            return L10n.Localizable.discoverRegionPhilippines
        case "poland":
            return L10n.Localizable.discoverRegionPoland
        case "portugal":
            return L10n.Localizable.discoverRegionPortugal
        case "Russia":
            return L10n.Localizable.discoverRegionRussia
        case "saudi arabia":
            return L10n.Localizable.discoverRegionSaudiArabia
        case "singapore":
            return L10n.Localizable.discoverRegionSingapore
        case "south africa":
            return L10n.Localizable.discoverRegionSouthAfrica
        case "south korea":
            return L10n.Localizable.discoverRegionSouthKorea
        case "spain":
            return L10n.Localizable.discoverRegionSpain
        case "sweden":
            return L10n.Localizable.discoverRegionSweden
        case "switzerland":
            return L10n.Localizable.discoverRegionSwitzerland
        case "taiwan":
            return L10n.Localizable.discoverRegionTaiwan
        case "turkey":
            return L10n.Localizable.discoverRegionTurkey
        case "ukraine":
            return L10n.Localizable.discoverRegionUkraine
        case "united kingdom":
            return L10n.Localizable.discoverRegionUnitedKingdom
        case "united states":
            return L10n.Localizable.discoverRegionUnitedStates
        case "worldwide":
            return L10n.Localizable.discoverRegionWorldwide

        // Catch all
        default:
            return self
        }
    }
}
