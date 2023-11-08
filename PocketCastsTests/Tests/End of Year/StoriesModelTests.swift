import XCTest
import SwiftUI

@testable import podcasts

@MainActor
class StoriesModelTests: XCTestCase {
    func testCurrentStoryAndProgressStartsInZero() {
        let model = StoriesModel(dataSource: MockStoriesDataSource(),
                                 configuration: StoriesConfiguration())

        XCTAssertEqual(model.currentStoryIndex, 0)
        XCTAssertEqual(model.progress, 0)
    }

    func testNumberOfStoriesReflectDataSourceValue() {
        let model = StoriesModel(dataSource: MockStoriesDataSource(),
                                 configuration: StoriesConfiguration())

        XCTAssertEqual(model.numberOfStories, 2)
    }

    func testProgressChangesAfterStart() {
        let model = StoriesModel(dataSource: MockStoriesDataSource(),
                                 configuration: StoriesConfiguration())

        model.start()

        eventually {
            XCTAssertTrue(model.progress > 0)
        }
    }

    func testNext() {
        let model = StoriesModel(dataSource: MockStoriesDataSource(),
                                 configuration: StoriesConfiguration())
        model.isReady = true
        model.start()

        model.next()

        eventually {
            XCTAssertEqual(model.currentStoryIndex, 1)
        }
    }

    func testPrevious() {
        let model = StoriesModel(dataSource: MockStoriesDataSource(),
                                 configuration: StoriesConfiguration())
        model.start()
        model.next()

        model.previous()

        eventually {
            XCTAssertEqual(model.currentStoryIndex, 0)
        }
    }

    func testWhenCallingStoryTheDataSourceIsCalledForTheView() {
        let dataSource = MockStoriesDataSource()
        let model = StoriesModel(dataSource: dataSource,
                                 configuration: StoriesConfiguration())

        _ = model.story(index: 0)

        XCTAssertEqual(dataSource.didCallStoryForWithStoryNumber, 0)
    }

    // MARK: - Plus stories

    /// If a user has a non-paid account we want to show only the first Plus story
    /// and skip all the following ones to the next non-Plus story.
    /// This way they don't see the same upsell multiple times.
    func testSkipToFirstNonPlusStoryIfFreeUser() {
        let model = StoriesModel(dataSource: MockStoriesWithPlusDataSource(),
                                 configuration: StoriesConfiguration(),
                                 activeTier: .none)
        model.isReady = true
        model.start()
        _ = model.story(index: 0)

        model.next()

        eventually(timeout: 0.1) {
            XCTAssertEqual(model.currentStoryIndex, 3)
        }
    }


    /// If a user has a non-paid account and they want to go to the previous story
    /// and it's a plus story, we want to show the first Plus story only.
    /// This way they don't see the same upsell multiple times.
    func testReturnToFirstPlusStoryIfFreeUser() {
        let model = StoriesModel(dataSource: MockStoriesWithPlusDataSource(),
                                 configuration: StoriesConfiguration(),
                                 activeTier: .none)
        model.start()
        _ = model.story(index: 0)

        model.next()
        model.previous()

        eventually(timeout: 0.1) {
            XCTAssertEqual(model.currentStoryIndex, 0)
        }
    }

    /// If the user is paid, don't skip
    func testDontSkipToFirstNonPlusStoryIfPatronUser() {
        let model = StoriesModel(dataSource: MockStoriesWithPlusDataSource(),
                                 configuration: StoriesConfiguration(),
                                 activeTier: .plus)
        model.isReady = true
        model.start()
        _ = model.story(index: 0)

        model.next()

        eventually(timeout: 0.1) {
            XCTAssertEqual(model.currentStoryIndex, 1)
        }
    }


    /// If the user is paid, don't return to the first plus story
    /// Instead, just go back normally.
    func testDontReturnToFirstPlusStoryIfPatronUser() {
        let model = StoriesModel(dataSource: MockStoriesWithPlusDataSource(),
                                 configuration: StoriesConfiguration(),
                                 activeTier: .patron)
        model.isReady = true
        model.start()
        _ = model.story(index: 0)

        model.next()
        model.next()
        model.next()
        model.currentStoryIndex = 3
        model.previous()

        eventually(timeout: 0.1) {
            XCTAssertEqual(model.currentStoryIndex, 2)
        }
    }
}

class MockStoriesDataSource: StoriesDataSource {
    var numberOfStories: Int = 2

    var didCallStoryForWithStoryNumber: Int?

    func story(for storyNumber: Int) -> any StoryView {
        didCallStoryForWithStoryNumber = storyNumber

        switch storyNumber {
        case 0:
            return MockedStory()
        default:
            return MockedStoryTwo()
        }
    }

    func shareableStory(for storyNumber: Int) -> (any ShareableStory)? {
        nil
    }

    func isReady() async -> Bool {
        true
    }

    func refresh() async -> Bool {
        true
    }
}

class MockStoriesWithPlusDataSource: StoriesDataSource {
    var numberOfStories: Int = 4

    var didCallStoryForWithStoryNumber: Int?

    func story(for storyNumber: Int) -> any StoryView {
        didCallStoryForWithStoryNumber = storyNumber

        switch storyNumber {
        case 0:
            return MockedPlusStory()
        case 1:
            return MockedPlusStory()
        case 2:
            return MockedPlusStory()
        case 3:
            return MockedStory()
        default:
            return MockedStoryTwo()
        }
    }

    func shareableStory(for storyNumber: Int) -> (any ShareableStory)? {
        nil
    }

    func isReady() async -> Bool {
        true
    }

    func refresh() async -> Bool {
        true
    }
}

struct MockedStory: StoryView {
    var duration: TimeInterval = 5 * 60

    var body: some View {
        ZStack {
            Color.purple
        }
    }
}

struct MockedStoryTwo: StoryView {
    var duration: TimeInterval = 5 * 60

    var body: some View {
        ZStack {
            Color.yellow
        }
    }
}

struct MockedPlusStory: StoryView {
    var duration: TimeInterval = 5 * 60

    var plusOnly = true

    var body: some View {
        ZStack {
            Color.yellow
        }
    }
}
