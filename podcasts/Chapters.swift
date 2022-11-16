//
//  Chapters.swift
//  podcasts
//
//  Created by Maarut Chandegra on 11/11/2022.
//  Copyright © 2022 Shifty Jelly. All rights reserved.
//

import Foundation
import UIKit

class Chapters: Equatable {
    private var chapters = [ChapterInfo]()

    init(chapters: [ChapterInfo]) {
        self.chapters = chapters
    }

    func visibleChapter() -> ChapterInfo? {
        chapters.last(where: { !$0.isHidden })
    }

    func title() -> String {
        visibleChapter()?.title ?? ""
    }

#if !os(watchOS)
    func artwork() -> UIImage? {
        chapters.last(where: { $0.image != nil })?.image
    }
#endif

    func count() -> Int {
        chapters.count
    }

    func index() -> Int {
        visibleChapter()?.index ?? -1
    }

    func url() -> String? {
        chapters.last(where: { $0.url != nil })?.url
    }

    func startTime() -> CMTime {
        visibleChapter()?.startTime ??
        chapters.min(by: { $0.startTime < $1.startTime} )?.startTime ??
        CMTime()
    }

    func duration() -> TimeInterval {
        visibleChapter()?.duration ??
        chapters.max(by: { $0.duration < $1.duration })?.duration ??
        1
    }

    static func == (lhs: Chapters, rhs: Chapters) -> Bool {
        lhs.chapters.elementsEqual(rhs.chapters)
    }
}
