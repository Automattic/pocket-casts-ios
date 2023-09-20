//
//  AppIntent.swift
//  WatchWidget
//
//  Created by Leandro Alonso on 20/09/23.
//  Copyright © 2023 Shifty Jelly. All rights reserved.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}
