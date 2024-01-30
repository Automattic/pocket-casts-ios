import DifferenceKit
import Foundation
import PocketCastsDataModel

struct EpisodeTableHelper {
    static func loadEpisodes(tintColor: UIColor = AppTheme.appTintColor(), query: String, arguments: [Any]?) -> [ListEpisode] {
        let loadedEpisodes = DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: arguments)

        var newData = [ListEpisode]()
        for episode in loadedEpisodes {
            let isInUpNext = PlaybackManager.shared.inUpNext(episode: episode)
            newData.append(ListEpisode(episode: episode, tintColor: tintColor, isInUpNext: isInUpNext))
        }

        return newData
    }

    static func loadSectionedEpisodes(tintColor: UIColor = AppTheme.appTintColor(), query: String, arguments: [Any]?, episodeShortKey: (Episode) -> String) -> [ArraySection<String, ListEpisode>] {
        let loadedEpisodes = DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: arguments)

        var previousSectionName = ""
        var currSectionIndex = -1
        var newData = [ArraySection<String, ListEpisode>]()
        for episode in loadedEpisodes {
            let currSectionName = episodeShortKey(episode)

            let isInUpNext = PlaybackManager.shared.inUpNext(episode: episode)
            if previousSectionName == currSectionName {
                var existingSection = newData[currSectionIndex]
                let listEpisode = ListEpisode(episode: episode, tintColor: tintColor, isInUpNext: isInUpNext)
                existingSection.elements.append(listEpisode)
                newData[currSectionIndex] = existingSection
            } else {
                let listEpisode = ListEpisode(episode: episode, tintColor: tintColor, isInUpNext: isInUpNext)
                newData.append(ArraySection(model: currSectionName, elements: [listEpisode]))
                currSectionIndex += 1
                previousSectionName = currSectionName
            }
        }

        return newData
    }

    static func loadSortedSectionedEpisodes(tintColor: UIColor = AppTheme.appTintColor(), query: String, arguments: [Any]?, sectionComparator: (String, String) -> Bool, episodeShortKey: (Episode) -> String) -> [ArraySection<String, ListItem>] {
        let loadedEpisodes = DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: arguments)

        var sections = [String: [ListEpisode]]()
        for episode in loadedEpisodes {
            let sectionKey = episodeShortKey(episode)

            let isInUpNext = PlaybackManager.shared.inUpNext(episode: episode)

            var section = sections[sectionKey] ?? [ListEpisode]()

            let listEpisode = ListEpisode(episode: episode, tintColor: tintColor, isInUpNext: isInUpNext)
            section.append(listEpisode)
            sections[sectionKey] = section
        }

        let sortedSections = sections.sorted { section1, section2 -> Bool in
            sectionComparator(section1.key, section2.key)
        }

        var newData = ArraySection<String, ListItem>(model: "episodes", elements: [])
        for section in sortedSections {
            newData.elements.append(ListHeader(headerTitle: section.key, isSectionHeader: false))
            newData.elements.append(contentsOf: section.value)
        }

        return [newData]
    }
}
