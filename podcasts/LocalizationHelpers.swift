import Foundation

public extension String {
    /// This allows us to split a strong and localize the first instance. This is particularly helpful with Podcast Categories.
    func localized(seperatingWith seperator: (Character) throws -> Bool) -> String? {
        if let substring = try? split(whereSeparator: seperator).first {
            return String(substring).localized
        } else {
            return localized
        }
    }

    func localized(with args: CVarArg...) -> String? {
        switch lowercased() {
        case "popular in [regionname]":
            return L10n.discoverPopularIn(args[0])
        default:
            return self
        }
    }

    /// This contains a list of strings that can come from the server. This method provides a helper to quickly lookup the localized versions.
    var localized: String {
        switch lowercased() {
        case "featured":
            return L10n.discoverFeatured

        // Discover Card Titles
        case "browse by category":
            return L10n.discoverBrowseByCategory
        case "popular":
            return L10n.discoverPopular
        case "trending":
            return L10n.discoverTrending

        // Categories
        case "arts":
            return L10n.discoverBrowseByCategoryArt
        case "business":
            return L10n.discoverBrowseByCategoryBusiness
        case "comedy":
            return L10n.discoverBrowseByCategoryComedy
        case "education":
            return L10n.discoverBrowseByCategoryEducation
        case "fiction":
            return L10n.discoverBrowseByCategoryFiction
        case "games & hobbies":
            return L10n.discoverBrowseByCategoryGamesAndHobbies
        case "government":
            return L10n.discoverBrowseByCategoryGovernment
        case "government & organizations":
            return L10n.discoverBrowseByCategoryGovernmentAndOrganizations
        case "health":
            return L10n.discoverBrowseByCategoryHealth
        case "health & fitness":
            return L10n.discoverBrowseByCategoryHealthAndFitness
        case "history":
            return L10n.discoverBrowseByCategoryHistory
        case "kids & family":
            return L10n.discoverBrowseByCategoryKidsAndFamily
        case "leisure":
            return L10n.discoverBrowseByCategoryLeisure
        case "music":
            return L10n.discoverBrowseByCategoryMusic
        case "news & politics":
            return L10n.discoverBrowseByCategoryNewsAndPolitics
        case "news":
            return L10n.discoverBrowseByCategoryNews
        case "religion & spirituality":
            return L10n.discoverBrowseByCategoryReligionAndSpirituality
        case "science":
            return L10n.discoverBrowseByCategoryScience
        case "science & medicine":
            return L10n.discoverBrowseByCategoryScienceAndMedicine
        case "society":
            return L10n.discoverBrowseByCategorySociety
        case "society & culture":
            return L10n.discoverBrowseByCategorySocietyAndCulture
        case "sports":
            return L10n.discoverBrowseByCategorySports
        case "sports & recreation":
            return L10n.discoverBrowseByCategorySportsAndRecreation
        case "technology":
            return L10n.discoverBrowseByCategoryTechnology
        case "true crime":
            return L10n.discoverBrowseByCategoryTrueCrime
        case "tv & film":
            return L10n.discoverBrowseByCategoryTvAndFilm

        // Abbreviated categories
        case "family":
            return L10n.discoverBrowseByCategoryFamily
        case "spirituality":
            return L10n.discoverBrowseByCategorySpirituality
        case "culture":
            return L10n.discoverBrowseByCategorySocietyAndCulture

        // Regions
        case "australia":
            return L10n.discoverRegionAustralia
        case "austria":
            return L10n.discoverRegionAustria
        case "belgium":
            return L10n.discoverRegionBelgium
        case "brazil":
            return L10n.discoverRegionBrazil
        case "canada":
            return L10n.discoverRegionCanada
        case "china":
            return L10n.discoverRegionChina
        case "czechia":
            return L10n.discoverRegionCzechia
        case "denmark":
            return L10n.discoverRegionDenmark
        case "finland":
            return L10n.discoverRegionFinland
        case "france":
            return L10n.discoverRegionFrance
        case "germany":
            return L10n.discoverRegionGermany
        case "hong kong":
            return L10n.discoverRegionHongKong
        case "india":
            return L10n.discoverRegionIndia
        case "ireland":
            return L10n.discoverRegionIreland
        case "israel":
            return L10n.discoverRegionIsrael
        case "italy":
            return L10n.discoverRegionItaly
        case "japan":
            return L10n.discoverRegionJapan
        case "mexico":
            return L10n.discoverRegionMexico
        case "netherlands":
            return L10n.discoverRegionNetherlands
        case "new zealand":
            return L10n.discoverRegionNewZealand
        case "norway":
            return L10n.discoverRegionNorway
        case "philippines":
            return L10n.discoverRegionPhilippines
        case "poland":
            return L10n.discoverRegionPoland
        case "portugal":
            return L10n.discoverRegionPortugal
        case "Russia":
            return L10n.discoverRegionRussia
        case "saudi arabia":
            return L10n.discoverRegionSaudiArabia
        case "singapore":
            return L10n.discoverRegionSingapore
        case "south africa":
            return L10n.discoverRegionSouthAfrica
        case "south korea":
            return L10n.discoverRegionSouthKorea
        case "spain":
            return L10n.discoverRegionSpain
        case "sweden":
            return L10n.discoverRegionSweden
        case "switzerland":
            return L10n.discoverRegionSwitzerland
        case "taiwan":
            return L10n.discoverRegionTaiwan
        case "turkey":
            return L10n.discoverRegionTurkey
        case "ukraine":
            return L10n.discoverRegionUkraine
        case "united kingdom":
            return L10n.discoverRegionUnitedKingdom
        case "united states":
            return L10n.discoverRegionUnitedStates
        case "worldwide":
            return L10n.discoverRegionWorldwide

        // Catch all
        default:
            return self
        }
    }
}
