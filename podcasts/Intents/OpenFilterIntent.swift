//
//  OpenFilter.swift
//  podcasts
//
//  Created by Brandon Titus on 6/16/25.
//  Copyright © 2025 Shifty Jelly. All rights reserved.
//

import Foundation
import AppIntents
import PocketCastsDataModel

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct FilterEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Filter"
    static var defaultQuery = FilterEntityQuery()
    
    var id: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    var name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct FilterEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [FilterEntity] {
        let allFilters = DataManager.sharedManager.allFilters(includeDeleted: false)
        return allFilters.compactMap { filter in
            guard identifiers.contains(filter.uuid) else { return nil }
            return FilterEntity(id: filter.uuid, name: filter.playlistName)
        }
    }
    
    func suggestedEntities() async throws -> [FilterEntity] {
        let allFilters = DataManager.sharedManager.allFilters(includeDeleted: false)
        return allFilters.map { filter in
            FilterEntity(id: filter.uuid, name: filter.playlistName)
        }
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct OpenFilter: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SJOpenFilterIntent"

    static var title: LocalizedStringResource = "Open Filter"
    static var description = IntentDescription("Open Filter")

    @Parameter(title: "Filter")
    var filter: FilterEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$filter)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$filter)) { filter in
            DisplayRepresentation(
                title: "Open \(filter?.name ?? "Filter")",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        let userActivity = NSUserActivity(activityType: "au.com.shiftyjelly.podcasts")

        userActivity.isEligibleForSearch = true
        if let filter {
            userActivity.title = "Open \(filter.name)"
            userActivity.suggestedInvocationPhrase = "Open \(filter.name)"
            userActivity.userInfo = ["filterUuid": filter.id]
        } else {
            userActivity.title = "Open Filter"
            userActivity.suggestedInvocationPhrase = "Open Filter"
        }
        userActivity.isEligibleForPrediction = true
        userActivity.becomeCurrent()

        return .result()
    }
}


